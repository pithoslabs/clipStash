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
    private var permissionTimer: Timer?
    private var permissionPollCount = 0
    private let maxPermissionPolls = 300  // Stop polling after 5 minutes (300 * 1 second)

    func applicationDidFinishLaunching(_ notification: Notification) {
        HotkeyManager.registerDefaults()

        if OnboardingWindowController.shared.shouldShow {
            OnboardingWindowController.shared.onFinish = { [weak self] in
                self?.setupApp()
            }
            OnboardingWindowController.shared.show()
        } else {
            setupApp()
        }
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

        reconcileHotkeyPreference()
    }

    func reconcileHotkeyPreference() {
        if HotkeyManager.isCommandVShortcutEnabled {
            if HotkeyManager.shared.start() {
                stopPermissionPolling()
            } else {
                // Accessibility permission not granted, will be prompted
                startPermissionPolling()
            }
        } else {
            stopPermissionPolling()
            HotkeyManager.shared.stop()
            PopupWindowController.shared.dismiss()
        }
    }

    private func startPermissionPolling() {
        guard permissionTimer == nil else { return }

        permissionPollCount = 0
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.permissionPollCount += 1

            guard HotkeyManager.isCommandVShortcutEnabled else {
                self.stopPermissionPolling()
                return
            }

            if HotkeyManager.shared.checkAccessibilityPermission() {
                self.stopPermissionPolling()
                _ = HotkeyManager.shared.start()
            } else if self.permissionPollCount >= self.maxPermissionPolls {
                // Stop polling after max attempts to save resources
                self.stopPermissionPolling()
            }
        }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopPermissionPolling()
        HotkeyManager.shared.stop()
        ClipboardMonitor.shared.stop()
    }
}
