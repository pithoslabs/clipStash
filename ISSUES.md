# ClipStash Issues to Fix

This document details bugs, security issues, and code quality problems identified in the ClipStash codebase.

---

## Fixed Issues

| Issue | Description | Fix |
|-------|-------------|-----|
| #1 | Plaintext storage of sensitive data | AES-GCM encryption with Keychain-stored key; auto-migration from legacy format |
| #2 | Race condition in paste flow | Use NSWorkspace activation notification instead of fixed delay; 500ms timeout fallback |
| #3 | Silent data loss on save failure | Added `@Published saveError`, retry logic (3 attempts), and UI warning in menu bar |
| #4 | Paste fails when no previous app exists | Always set clipboard content; only auto-paste if target app exists |
| #6 | Blocking main thread with usleep | Replace `usleep()` with `DispatchQueue.main.asyncAfter` |
| #7 | Permission timer not retained | Store timer in property; stop after 5 min or on termination |
| #8 | Unsynchronized access to history items | Added `@MainActor` to `HistoryStore` class |
| #16 | No size limit on clipboard content | Limit to 1MB; truncate with size marker if exceeded |

---

## Critical Issues

### 1. ~~Plaintext Storage of Sensitive Data~~ ✅ FIXED

**File:** `ClipStash/Services/HistoryStore.swift:20`

**Problem:**
Clipboard history is stored as unencrypted JSON at `~/Library/Application Support/ClipStash/history.json`. Users frequently copy sensitive data like passwords, API keys, credit card numbers, and personal information. Any application or user with file system access can read this file.

**Current Code:**
```swift
self.storageURL = appFolder.appendingPathComponent("history.json")
```

**Impact:**
- Privacy violation for users who expect clipboard data to be transient
- Security risk if machine is shared or compromised
- Potential compliance issues (GDPR, HIPAA) for enterprise users

**Recommended Fix:**
- Use macOS Keychain for storage, OR
- Encrypt the JSON file using a key stored in Keychain, OR
- At minimum, set restrictive file permissions (0600)

---

### 2. ~~Race Condition in Paste Flow~~ ✅ FIXED

**File:** `ClipStash/Views/PopupWindowController.swift:155`

**Problem:**
After selecting a clipboard item, the app waits an arbitrary 100ms before simulating the paste keystroke. This delay assumes the target app will be fully activated and ready to receive input, which is not guaranteed.

**Current Code:**
```swift
// Activate target
targetApp.activate()

// Wait for activation, then paste (our event is marked so it won't trigger popup)
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    PasteService.shared.paste()
}
```

**Impact:**
- On slower machines or under heavy load, paste may go to wrong app
- Inconsistent behavior that's hard to reproduce/debug
- User confusion when paste appears in unexpected location

**Recommended Fix:**
- Use `NSWorkspace` notifications to detect when target app is actually activated
- Implement a callback-based approach: `targetApp.activate(options:completionHandler:)`
- Add a maximum retry mechanism with proper failure feedback

---

### 3. ~~Silent Data Loss on Save Failure~~ ✅ FIXED

**File:** `ClipStash/Services/HistoryStore.swift:91-97`

**Problem:**
When saving clipboard history to disk fails (disk full, permissions changed, filesystem error), the error is only logged to console. The user receives no notification and continues using the app unaware that their history is not being persisted.

**Current Code:**
```swift
private func save() {
    do {
        let data = try JSONEncoder().encode(items)
        try data.write(to: storageURL, options: .atomic)
    } catch {
        print("Failed to save history: \(error)")
    }
}
```

**Impact:**
- Complete data loss on app restart after failed saves
- User trust violation - they believe data is saved
- No opportunity for user to take corrective action

**Recommended Fix:**
- Publish save errors via `@Published var saveError: Error?`
- Show user-facing alert for persistent save failures
- Implement retry logic with exponential backoff
- Consider in-memory fallback with periodic retry

---

## Bugs

### 4. ~~Paste Fails When No Previous App Exists~~ ✅ FIXED

**File:** `ClipStash/Views/PopupWindowController.swift:142-143`

**Problem:**
If ClipStash is the first app launched (or the previous app has quit), `previousApp` is nil. When the user selects a clipboard item, the function returns early without pasting. The popup closes but nothing happens.

**Current Code:**
```swift
private func handleItemSelected(_ item: ClipboardItem) {
    guard let targetApp = previousApp else { return }  // Silent early return!

    // Set clipboard
    ClipboardMonitor.shared.setContent(item.content)
    // ... rest never executes
}
```

**Impact:**
- User selects item, popup closes, nothing pastes
- No error message or feedback
- Confusing UX - appears broken

**Recommended Fix:**
```swift
private func handleItemSelected(_ item: ClipboardItem) {
    // Always set clipboard content
    ClipboardMonitor.shared.setContent(item.content)

    // Dismiss popup
    dismiss()

    // If we have a target app, activate it and paste
    if let targetApp = previousApp {
        targetApp.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PasteService.shared.paste()
        }
    }
    // If no target app, content is still on clipboard - user can paste manually
}
```

---

### 5. Wrong Source App Attribution

**File:** `ClipStash/Services/ClipboardMonitor.swift:34-35`

**Problem:**
The clipboard monitor polls every 500ms. When a change is detected, it captures the *current* frontmost app, not the app that performed the copy. If the user copies in App A and quickly switches to App B, the clip is attributed to App B.

**Current Code:**
```swift
private func checkForChanges() {
    let currentCount = pasteboard.changeCount
    guard currentCount != lastChangeCount else { return }
    lastChangeCount = currentCount

    // Gets app at detection time, not copy time
    let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

    guard let content = pasteboard.string(forType: .string) else { return }
    HistoryStore.shared.add(content, sourceApp: sourceApp)
}
```

**Impact:**
- Incorrect metadata displayed to user
- Misleading when searching/filtering by source
- Undermines trust in app accuracy

**Recommended Fix:**
- Track frontmost app continuously, store last known app
- Use the app that was frontmost *before* the change count changed
- Consider using `NSPasteboard` name attribute if available

---

### 6. ~~Blocking Main Thread with usleep~~ ✅ FIXED

**File:** `ClipStash/Services/PasteService.swift:35`

**Problem:**
`usleep(30000)` blocks the main thread for 30 milliseconds between posting key-down and key-up events. While 30ms is short, blocking the main thread is bad practice and can cause UI stuttering, especially if called during animations.

**Current Code:**
```swift
print("[PasteService] Posting keyDown...")
keyDown.post(tap: .cghidEventTap)
usleep(30000)  // Blocks main thread!
print("[PasteService] Posting keyUp...")
keyUp.post(tap: .cghidEventTap)
```

**Impact:**
- Potential UI stutter
- Violates Apple's guidance on main thread responsiveness
- Could cause watchdog termination if combined with other delays

**Recommended Fix:**
```swift
keyDown.post(tap: .cghidEventTap)
DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
    keyUp.post(tap: .cghidEventTap)
}
```

---

### 7. ~~Memory Leak: Permission Polling Timer Not Retained~~ ✅ FIXED

**File:** `ClipStash/ClipStashApp.swift:43-50`

**Problem:**
The timer that polls for accessibility permission is not stored in a property. While it runs due to RunLoop retention, this is implicit behavior. More importantly, if permission is never granted, this timer runs forever with no way to stop it.

**Current Code:**
```swift
// Poll for permission
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
    if HotkeyManager.shared.checkAccessibilityPermission() {
        timer.invalidate()
        if HotkeyManager.shared.start() {
            print("Hotkey manager started successfully")
        }
    }
}
// Timer reference is lost immediately
```

**Impact:**
- Timer runs indefinitely if permission never granted
- No way to stop polling programmatically
- Unnecessary CPU wake-ups every second

**Recommended Fix:**
```swift
private var permissionTimer: Timer?

// In setupApp():
permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
    if HotkeyManager.shared.checkAccessibilityPermission() {
        timer.invalidate()
        self?.permissionTimer = nil
        _ = HotkeyManager.shared.start()
    }
}
```

---

## Thread Safety Issues

### 8. ~~Unsynchronized Access to History Items~~ ✅ FIXED

**File:** `ClipStash/Services/HistoryStore.swift`

**Problem:**
The `items` array is accessed from multiple threads without synchronization:
- Main thread: UI reads via `@Published`
- Timer thread: `cleanup()` called from `cleanupTimer`
- Event tap thread: `HotkeyManager.handleEvent` checks `HistoryStore.shared.items.isEmpty`

**Current Code (multiple access points):**
```swift
// Main thread - UI binding
@Published private(set) var items: [ClipboardItem] = []

// Timer thread - cleanup
private func startCleanupTimer() {
    cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
        self?.cleanup()  // Modifies items on timer thread
    }
}

// Event tap thread (HotkeyManager.swift:105)
let hasHistoryItems = !HistoryStore.shared.items.isEmpty  // Read on callback thread
```

**Impact:**
- Potential crashes (EXC_BAD_ACCESS)
- Data corruption (partial reads during writes)
- Undefined behavior

**Recommended Fix:**
- Use `@MainActor` for the entire `HistoryStore` class, OR
- Use a serial `DispatchQueue` for all `items` access, OR
- Convert to Swift actor

---

## UX Issues

### 9. Force Unwrap on System Directory

**File:** `ClipStash/Services/HistoryStore.swift:15`

**Problem:**
Force unwrapping the Application Support directory URL. While extremely unlikely to fail, force unwraps should be avoided, especially in initialization paths.

**Current Code:**
```swift
let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
```

**Recommended Fix:**
```swift
guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
    fatalError("Could not locate Application Support directory")
}
```

---

### 10. Keyboard Shortcuts Depend on Layout

**File:** `ClipStash/Views/PopupView.swift:177`

**Problem:**
Using `event.characters` to detect number keys depends on the keyboard layout. On international keyboards or with alternative input methods, Cmd+1-9 may produce different characters.

**Current Code:**
```swift
if event.modifierFlags.contains(.command) {
    if let number = Int(event.characters ?? ""), number >= 1 && number <= 9 {
        let index = number - 1
        // ...
    }
}
```

**Impact:**
- Quick-select shortcuts don't work on some keyboard layouts
- International users frustrated

**Recommended Fix:**
```swift
// Use keyCode instead of characters
let keyCode = event.keyCode
let numberKeyCodes: [UInt16: Int] = [
    18: 1, 19: 2, 20: 3, 21: 4, 23: 5, 22: 6, 26: 7, 28: 8, 25: 9  // kVK_ANSI_1 through kVK_ANSI_9
]
if event.modifierFlags.contains(.command), let number = numberKeyCodes[keyCode] {
    let index = number - 1
    // ...
}
```

---

### 11. Popup Always Appears on Main Screen

**File:** `ClipStash/Views/PopupWindowController.swift:86`

**Problem:**
The popup always centers on `NSScreen.main`, regardless of which screen the user is working on in a multi-monitor setup.

**Current Code:**
```swift
if let screen = NSScreen.main {
    let screenFrame = screen.visibleFrame
    // ... centers popup on main screen
}
```

**Impact:**
- User working on secondary monitor must look at primary monitor
- Disruptive workflow for multi-monitor users

**Recommended Fix:**
```swift
// Use screen containing mouse cursor
if let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main {
    let screenFrame = screen.visibleFrame
    // ...
}
```

---

### 12. Fixed Window Size

**File:** `ClipStash/Views/PopupView.swift:115`

**Problem:**
The popup has a hardcoded size of 420x380 points. It doesn't adapt to:
- System font size / accessibility settings
- Content length
- Screen resolution / scaling

**Current Code:**
```swift
.frame(width: 420, height: 380)
```

**Impact:**
- Accessibility issues for users with larger system fonts
- Wasted space when few items in history
- May be too small on high-resolution displays

**Recommended Fix:**
- Use `minWidth`/`maxWidth` and `minHeight`/`maxHeight` for flexible sizing
- Calculate height based on item count (with min/max bounds)
- Respect system Dynamic Type settings

---

## Code Quality Issues

### 13. Debug Print Statements in Production

**Files:**
- `ClipStash/Services/HotkeyManager.swift` (lines 94, 97, 108, 115, 119)
- `ClipStash/Services/PasteService.swift` (lines 14, 18, 33, 36, 38)
- `ClipStash/Views/PopupWindowController.swift` (lines 44, 46)

**Problem:**
Numerous `print()` statements throughout the codebase that will appear in Console.app for end users. This is unprofessional and clutters system logs.

**Examples:**
```swift
print("[HotkeyManager] Cmd+V detected, userData: \(userData), marker: \(PasteService.markerValue)")
print("[PasteService] Creating paste events with marker: \(PasteService.markerValue)")
print("[ClipStash] Stored previousApp: \(previousApp?.localizedName ?? "nil")")
```

**Recommended Fix:**
- Remove all debug prints, OR
- Use `os_log` with appropriate log levels, OR
- Use `#if DEBUG` guards:
```swift
#if DEBUG
print("[HotkeyManager] Cmd+V detected")
#endif
```

---

### 14. Magic Numbers for Key Codes

**File:** `ClipStash/Views/PopupView.swift:144-167`

**Problem:**
Key codes are hardcoded as magic numbers with only comments for documentation. This is fragile and hard to maintain.

**Current Code:**
```swift
switch Int(event.keyCode) {
case 125: // Down arrow
case 126: // Up arrow
case 36: // Return/Enter
case 53: // Escape
case 51: // Delete/Backspace
```

**Recommended Fix:**
```swift
import Carbon.HIToolbox

switch Int(event.keyCode) {
case kVK_DownArrow:
case kVK_UpArrow:
case kVK_Return:
case kVK_Escape:
case kVK_Delete:
```

---

### 15. Redundant Callback Architecture

**Files:**
- `ClipStash/Models/PopupState.swift`
- `ClipStash/Views/PopupView.swift`
- `ClipStash/Views/PopupWindowController.swift`

**Problem:**
There are three overlapping mechanisms for handling item selection and dismissal:
1. `PopupState.shared.onItemSelected` / `onDismiss`
2. `PopupView` constructor parameters `onItemSelected` / `onDismiss`
3. `PopupWindowController` sets both of the above

**Current Code:**
```swift
// PopupWindowController.swift:50-56
PopupState.shared.onItemSelected = { [weak self] item in
    self?.handleItemSelected(item)
}
PopupState.shared.onDismiss = { [weak self] in
    self?.dismiss()
}

// PopupWindowController.swift:58-65
let view = PopupView(
    onItemSelected: { [weak self] item in
        self?.handleItemSelected(item)
    },
    onDismiss: { [weak self] in
        self?.dismiss()
    }
)
```

**Impact:**
- Confusing architecture
- Easy to forget to wire up one path
- Potential for callbacks to get out of sync

**Recommended Fix:**
- Choose one pattern and remove the other
- Recommended: Use only `PopupState.shared` callbacks (already observable)
- Remove callback parameters from `PopupView`

---

### 16. ~~No Size Limit on Clipboard Content~~ ✅ FIXED

**File:** `ClipStash/Services/ClipboardMonitor.swift:38-40`

**Problem:**
There's no check on the size of clipboard content before storing it. Copying a large text file (e.g., 100MB log file) would store the entire content in memory and persist it to disk.

**Current Code:**
```swift
guard let content = pasteboard.string(forType: .string) else { return }
HistoryStore.shared.add(content, sourceApp: sourceApp)  // No size check!
```

**Impact:**
- Memory exhaustion with large clipboard content
- Huge history.json file
- Slow app startup when loading history
- Potential crash on low-memory devices

**Recommended Fix:**
```swift
guard let content = pasteboard.string(forType: .string) else { return }

// Limit to 1MB of text
let maxContentSize = 1_000_000
if content.utf8.count > maxContentSize {
    let truncated = String(content.prefix(maxContentSize))
    HistoryStore.shared.add(truncated + "... [truncated]", sourceApp: sourceApp)
} else {
    HistoryStore.shared.add(content, sourceApp: sourceApp)
}
```

---

## Summary

| Category | Count | Issues | Fixed |
|----------|-------|--------|-------|
| Critical | 3 | #1, #2, #3 | 3 (#1, #2, #3) |
| Bugs | 4 | #4, #5, #6, #7 | 3 (#4, #6, #7) |
| Thread Safety | 1 | #8 | 1 (#8) |
| UX | 4 | #9, #10, #11, #12 | 0 |
| Code Quality | 4 | #13, #14, #15, #16 | 1 (#16) |
| **Total** | **16** | | **8 fixed** |

## Priority Order for Fixes

1. ~~**#8** - Thread safety (crash risk)~~ ✅ FIXED
2. ~~**#4** - Paste fails silently (broken functionality)~~ ✅ FIXED
3. ~~**#3** - Silent data loss (data integrity)~~ ✅ FIXED
4. ~~**#1** - Plaintext storage (security)~~ ✅ FIXED
5. ~~**#2** - Race condition in paste (reliability)~~ ✅ FIXED
6. ~~**#16** - No size limit (memory safety)~~ ✅ FIXED
7. ~~**#6** - Blocking main thread (performance)~~ ✅ FIXED
8. ~~**#7** - Timer leak (resource management)~~ ✅ FIXED
9. **#5** - Wrong source attribution (accuracy)
10. **#10** - Keyboard layout (internationalization)
11. **#11** - Multi-monitor support (usability)
12. **#13** - Debug prints (professionalism)
13. **#14** - Magic numbers (maintainability)
14. **#15** - Redundant callbacks (code quality)
15. **#9** - Force unwrap (robustness)
16. **#12** - Fixed size (accessibility)
