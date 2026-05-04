import AppKit
import Carbon.HIToolbox

final class PasteService {
    static let shared = PasteService()

    // Magic number to mark our events
    static let markerValue: Int64 = 0x434C4950  // "CLIP" in hex

    private init() {}

    func paste(to application: NSRunningApplication? = nil) {
        let keyCodeV = CGKeyCode(kVK_ANSI_V)

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCodeV, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCodeV, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        // Mark events as ours using userData field
        keyDown.setIntegerValueField(.eventSourceUserData, value: PasteService.markerValue)
        keyUp.setIntegerValueField(.eventSourceUserData, value: PasteService.markerValue)

        post(keyDown, to: application)

        // Post keyUp after brief delay without blocking main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [application] in
            self.post(keyUp, to: application)
        }
    }

    private func post(_ event: CGEvent, to application: NSRunningApplication?) {
        if let application {
            event.postToPid(application.processIdentifier)
        } else {
            event.post(tap: .cghidEventTap)
        }
    }
}
