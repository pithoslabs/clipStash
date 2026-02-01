import AppKit
import SwiftUI

// Custom window that can become key even when borderless
final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// Custom hosting view that accepts first mouse click immediately
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class PopupWindowController {
    static let shared = PopupWindowController()

    private var window: NSWindow?
    private var popupView: PopupView?
    private var hostingView: NSHostingView<PopupView>?
    private var eventMonitor: Any?
    private var mouseMonitor: Any?
    private var globalClickMonitor: Any?
    private var previousApp: NSRunningApplication?
    private var activationObserver: Any?
    private var activationTimeoutTask: DispatchWorkItem?

    private init() {}

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    func show() {
        if window != nil {
            dismiss()
        }

        // Remember which app was active before showing popup
        // But don't store our own app - keep the previous value if current is us
        let currentFrontApp = NSWorkspace.shared.frontmostApplication
        let ourBundleId = Bundle.main.bundleIdentifier

        if currentFrontApp?.bundleIdentifier != ourBundleId {
            previousApp = currentFrontApp
            print("[ClipStash] Stored previousApp: \(previousApp?.localizedName ?? "nil")")
        } else {
            print("[ClipStash] Current frontmost is us, keeping previousApp: \(previousApp?.localizedName ?? "nil")")
        }

        // Reset shared state and set callbacks
        PopupState.shared.reset()
        PopupState.shared.onItemSelected = { [weak self] item in
            self?.handleItemSelected(item)
        }
        PopupState.shared.onDismiss = { [weak self] in
            self?.dismiss()
        }

        let view = PopupView(
            onItemSelected: { [weak self] item in
                self?.handleItemSelected(item)
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )
        popupView = view

        let hostingView = FirstMouseHostingView(rootView: view)
        self.hostingView = hostingView

        let window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = false

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2 + 100 // Slightly above center
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Monitor for key events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.popupView?.handleKeyDown(event) == true {
                return nil
            }
            return event
        }

        // Monitor for mouse clicks on items
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            if self?.popupView?.handleMouseDown(event) == true {
                return nil
            }
            return event
        }

        // Monitor for clicks outside
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }

        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }

        window?.orderOut(nil)
        window = nil
        hostingView = nil
        popupView = nil
    }

    private func handleItemSelected(_ item: ClipboardItem) {
        // Always set clipboard content first
        ClipboardMonitor.shared.setContent(item.content)

        // Dismiss popup
        dismiss()

        // If we have a target app, activate it and paste
        // Otherwise, content is on clipboard for user to paste manually
        guard let targetApp = previousApp else { return }

        // Set up observer for app activation before requesting activation
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let activatedApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  activatedApp.processIdentifier == targetApp.processIdentifier else {
                return
            }

            // Target app is now active - paste and clean up
            self?.cleanupActivationObserver()
            PasteService.shared.paste()
        }

        // Set up timeout in case activation notification never fires
        let timeoutTask = DispatchWorkItem { [weak self] in
            guard self?.activationObserver != nil else { return }

            // Timeout reached - check if app is frontmost and paste anyway
            self?.cleanupActivationObserver()
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == targetApp.processIdentifier {
                PasteService.shared.paste()
            }
        }
        activationTimeoutTask = timeoutTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: timeoutTask)

        // Request activation
        targetApp.activate()
    }

    private func cleanupActivationObserver() {
        if let observer = activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            activationObserver = nil
        }
        activationTimeoutTask?.cancel()
        activationTimeoutTask = nil
    }
}
