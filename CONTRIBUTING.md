# Contributing to ClipStash

Thanks for helping improve ClipStash. This project is a macOS clipboard utility, so privacy, predictable paste behavior, and native platform quality matter more than feature volume.

ClipStash is source-available for noncommercial use. By contributing, you agree that your contribution may be distributed under the project license and under separate commercial licenses granted by Pithos Labs.

## Development Setup

1. Install Xcode 15 or later.
2. Clone the repository.
3. Open `ClipStash.xcodeproj`.
4. Build the `ClipStash` scheme.
5. Grant Accessibility permission when testing global shortcut behavior.

## Running Tests

Use Xcode, or run:

```sh
xcodebuild test -project ClipStash.xcodeproj -scheme ClipStash -destination 'platform=macOS'
```

Some behavior requires manual testing because it depends on macOS Accessibility permission, frontmost app activation, and pasteboard state.

## Pull Requests

- Keep changes focused.
- Include tests for model, storage, filtering, and state changes when practical.
- Manually test changes that affect `Cmd+V`, popup focus, paste behavior, Accessibility permission, clipboard monitoring, or encrypted storage.
- Avoid adding network calls, analytics, telemetry, or cloud behavior without a clear privacy discussion.
- Do not commit signing certificates, provisioning profiles, local Xcode user data, `.DS_Store`, `.vercel/`, generated `.app` bundles, `.dmg` files, or machine-specific settings.
- Do not add code or assets that conflict with the project license or require commercial redistribution rights Pithos Labs does not have.

## Coding Style

- Prefer native AppKit/SwiftUI APIs and simple local abstractions.
- Keep UI behavior keyboard-friendly.
- Make privacy-impacting behavior explicit in code and docs.
- Avoid broad refactors in feature or bug-fix pull requests.

## Reporting Bugs

When opening an issue, include:

- macOS version
- ClipStash version or commit hash
- Steps to reproduce
- Expected behavior
- Actual behavior
- Whether Accessibility permission is granted

Do not include sensitive clipboard contents in public issues.
