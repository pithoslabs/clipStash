# ClipStash — App Store Metadata

## App Name
ClipStash

## Subtitle (30 characters max)
Your clipboard, remembered.

## Promotional Text (170 characters max)
Never lose a copied item again. ClipStash keeps your clipboard history at your fingertips—just press Cmd+V.

## Description
**Your clipboard, remembered.**

ClipStash is a beautifully simple clipboard history manager for macOS. Press Cmd+V—the shortcut you already use—and instantly access everything you've copied.

**Why ClipStash?**

Unlike other clipboard managers that require learning new shortcuts, ClipStash enhances your existing workflow. Just paste like you always do, but now you can choose from your entire clipboard history.

**Features:**

• **Cmd+V Integration** — No new shortcuts to learn. Press your normal paste shortcut and see your history.

• **Lightning Fast** — Native macOS app built with SwiftUI. No Electron, no bloat—just instant response.

• **Keyboard First** — Navigate with arrow keys, search by typing, paste with Enter or Cmd+1-9.

• **Beautiful UI** — Liquid glass design that feels right at home on macOS. Supports dark mode.

• **Instant Search** — Find anything you've copied. Just start typing to filter your history.

• **Completely Private** — Everything stays on your Mac. No cloud sync, no analytics, no tracking. Ever.

• **Smart & Clean** — Auto-cleanup after 24 hours. No duplicates. Just the clips that matter.

• **Source Tracking** — See which app each clip came from.

**Privacy First**

ClipStash stores your clipboard history locally in encrypted storage at ~/Library/Application Support/ClipStash/history.encrypted, with the encryption key stored in macOS Keychain. Your data never leaves your device. We don't collect analytics, track usage, or phone home. Your clipboard is your business.

**Requirements**

• macOS 13 Ventura or later
• Apple Silicon or Intel Mac
• Accessibility permission (for Cmd+V interception)

---

Built with care by Pithos Labs.

## Keywords (100 characters max)
clipboard,history,paste,copy,manager,productivity,utility,cmd+v,snippets,text

## Categories
- Primary: Utilities
- Secondary: Productivity

## Age Rating
4+ (No objectionable content)

## Copyright
© 2026 Pithos Labs

## Support URL
https://github.com/pithoslabs/clipStash

## Privacy Policy URL
https://pithoslabs.github.io/clipStash/privacy.html

## Marketing URL (optional)
https://pithoslabs.github.io/clipStash

---

## Screenshots Required

### Mac App Store (1280x800 or 1440x900)

1. **Hero Shot** — ClipStash popup with multiple clipboard items, search bar visible
2. **Keyboard Shortcuts** — Show the Cmd+V trigger and Cmd+1-9 quick paste
3. **Search Feature** — Popup with search query filtering items
4. **Source App Tracking** — Items showing "Safari", "VS Code", etc.
5. **Dark Mode** — Full dark mode appearance

### Screenshot Captions
1. "Press Cmd+V to see your clipboard history"
2. "Paste any item with Cmd+1 through Cmd+9"
3. "Search through everything you've copied"
4. "See which app each clip came from"
5. "Beautiful in light and dark mode"

---

## App Preview Video (optional, 15-30 seconds)

Suggested flow:
1. Show copying text in Safari
2. Copy code in VS Code
3. Copy text in Notes
4. Press Cmd+V in a document
5. ClipStash popup appears with all three items
6. Use arrow keys to navigate
7. Press Enter to paste
8. Show search filtering
9. End with tagline: "Your clipboard, remembered."

---

## What's New (Version 1.0)
Initial release of ClipStash—your clipboard, remembered.

• Access clipboard history with Cmd+V
• Search and filter your history
• Keyboard navigation with arrow keys and Cmd+1-9
• 24-hour auto-cleanup
• Native macOS app with liquid glass UI
• Completely private—no data collection

---

## Review Notes (for App Store Review)

ClipStash requires Accessibility permission to intercept the Cmd+V keyboard shortcut. This is essential for the core functionality—when users press Cmd+V, we show the clipboard history popup instead of immediately pasting.

The app uses CGEvent tap to detect Cmd+V presses and simulates paste events after the user selects an item. This is similar to how other clipboard managers work (Paste, Maccy, etc.).

To test:
1. Launch ClipStash
2. Grant Accessibility permission when prompted
3. Copy some text in any app
4. Press Cmd+V—you should see the ClipStash popup
5. Press Enter or click an item to paste

The app stores encrypted data locally at ~/Library/Application Support/ClipStash/history.encrypted, keeps the encryption key in macOS Keychain, and does not make any network connections.
