import AppKit
import Carbon.HIToolbox

final class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onPasteTriggered: (() -> Void)?

    private init() {}

    func start() -> Bool {
        guard checkAccessibilityPermission() else {
            requestAccessibilityPermission()
            return false
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }

        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
    }

    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // Handle tap disabled event (system can disable taps if too slow)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // Check for Cmd+V (keyCode 9 is 'V')
        let isCommandPressed = flags.contains(.maskCommand)
        let isNoOtherModifiers = !flags.contains(.maskShift) &&
                                  !flags.contains(.maskAlternate) &&
                                  !flags.contains(.maskControl)

        if keyCode == kVK_ANSI_V && isCommandPressed && isNoOtherModifiers {
            // Check if this is our own simulated event
            let userData = event.getIntegerValueField(.eventSourceUserData)

            if userData == PasteService.markerValue {
                return Unmanaged.passRetained(event)
            }

            // Check clipboard content type
            let pasteboard = NSPasteboard.general

            // Only intercept if clipboard contains purely text content
            // Let native paste handle files, images, app-specific data (video editors, design tools, etc.)
            if !isPlainTextClipboard(pasteboard) {
                return Unmanaged.passRetained(event)
            }

            // Check if clipboard has text content we can handle
            let hasTextContent = pasteboard.string(forType: .string) != nil
            let hasHistoryItems = HistoryStore.shared.hasItems

            if !hasTextContent && !hasHistoryItems {
                return Unmanaged.passRetained(event)
            }

            if !hasTextContent {
                return Unmanaged.passRetained(event)
            }

            DispatchQueue.main.async { [weak self] in
                self?.onPasteTriggered?()
            }
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Check if clipboard contains only standard text types (no app-specific data)
    /// Returns false for files, images, video editor timeline items, design tool objects, etc.
    private func isPlainTextClipboard(_ pasteboard: NSPasteboard) -> Bool {
        guard let types = pasteboard.types else { return false }

        // Standard text-related UTIs that we should handle
        let textTypes: Set<String> = [
            "public.plain-text",
            "public.utf8-plain-text",
            "public.utf16-plain-text",
            "public.utf16-external-plain-text",
            "public.rtf",
            "public.html",
            "public.text",
            "NSStringPboardType",
            "NeXT plain ascii pasteboard type",
            "CorePasteboardFlavorType 0x54455854",  // TEXT
            "dyn.ah62d4rv4gu8y63n2nuuhg5pbsm4ca6dbsr4gnkdcarmc65zhm",  // Dynamic text type
        ]

        // Types to explicitly reject (files, images, app-specific content)
        for type in types {
            let typeStr = type.rawValue

            // Reject file URLs
            if typeStr.contains("file-url") || typeStr.contains("NSFilenamesPboardType") {
                return false
            }

            // Reject images
            if typeStr.contains("public.image") || typeStr.contains("public.png") ||
               typeStr.contains("public.jpeg") || typeStr.contains("public.tiff") {
                return false
            }

            // Reject app-specific types (com.company.app.*)
            // These indicate specialized content from apps like CapCut, Final Cut, Premiere, etc.
            if typeStr.hasPrefix("com.") && !typeStr.hasPrefix("com.apple.") {
                // Third-party app-specific type - let native paste handle it
                return false
            }

            // Reject dynamic types that aren't text (often app-specific)
            if typeStr.hasPrefix("dyn.") && !textTypes.contains(typeStr) {
                // Check if any non-text type exists alongside
                let hasNonTextDynType = types.contains { t in
                    t.rawValue.hasPrefix("dyn.") && !textTypes.contains(t.rawValue)
                }
                if hasNonTextDynType && types.count > 2 {
                    return false
                }
            }
        }

        return true
    }
}
