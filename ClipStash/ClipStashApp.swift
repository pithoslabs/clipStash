import SwiftUI
import AppKit

@main
struct ClipStashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("ClipStash", systemImage: "doc.on.clipboard") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApp()
    }

    private func setupApp() {
        // Initialize paste service (triggers automation permission check)
        _ = PasteService.shared

        // Start clipboard monitoring
        ClipboardMonitor.shared.start()

        // Setup hotkey manager
        HotkeyManager.shared.onPasteTriggered = {
            if PopupWindowController.shared.isVisible {
                PopupWindowController.shared.dismiss()
            } else {
                PopupWindowController.shared.show()
            }
        }

        // Start hotkey listening
        if !HotkeyManager.shared.start() {
            // Accessibility permission not granted, will be prompted
            print("Waiting for accessibility permission...")

            // Poll for permission
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if HotkeyManager.shared.checkAccessibilityPermission() {
                    timer.invalidate()
                    if HotkeyManager.shared.start() {
                        print("Hotkey manager started successfully")
                    }
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
        ClipboardMonitor.shared.stop()
    }
}
