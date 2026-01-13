import AppKit
import Carbon.HIToolbox

final class PasteService {
    static let shared = PasteService()

    // Magic number to mark our events
    static let markerValue: Int64 = 0x434C4950  // "CLIP" in hex

    private init() {}

    func paste() {
        let keyCodeV = CGKeyCode(kVK_ANSI_V)
        print("[PasteService] Creating paste events with marker: \(PasteService.markerValue)")

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCodeV, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCodeV, keyDown: false) else {
            print("[PasteService] ERROR: Failed to create events")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        // Mark events as ours using userData field
        keyDown.setIntegerValueField(.eventSourceUserData, value: PasteService.markerValue)
        keyUp.setIntegerValueField(.eventSourceUserData, value: PasteService.markerValue)

        // Verify marker was set
        let checkMarker = keyDown.getIntegerValueField(.eventSourceUserData)
        print("[PasteService] Marker verification: \(checkMarker)")

        print("[PasteService] Posting keyDown...")
        keyDown.post(tap: .cghidEventTap)
        usleep(30000)
        print("[PasteService] Posting keyUp...")
        keyUp.post(tap: .cghidEventTap)
        print("[PasteService] Done")
    }
}
