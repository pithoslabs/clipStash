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
            print("Failed to create event tap")
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
            print("[HotkeyManager] Cmd+V detected, userData: \(userData), marker: \(PasteService.markerValue)")

            if userData == PasteService.markerValue {
                print("[HotkeyManager] → Our event, passing through")
                return Unmanaged.passRetained(event)
            }

            print("[HotkeyManager] → User event, showing popup")
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
}
