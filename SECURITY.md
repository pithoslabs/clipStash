# Security Policy

ClipStash handles clipboard contents, which may include passwords, API keys, private documents, and other sensitive data. Please do not report security issues with sensitive details in public GitHub issues.

## Reporting a Vulnerability

Report security vulnerabilities privately by emailing info@pithoslabs.org or by using GitHub's private vulnerability reporting if it is enabled for this repository.

Please include:

- A concise description of the issue
- Steps to reproduce
- Affected macOS and ClipStash versions
- Potential impact
- Any suggested fix, if available

Avoid sharing real secrets or private clipboard contents. Use test values whenever possible.

## Scope

Security-sensitive areas include:

- Clipboard history storage and encryption
- Keychain key handling
- Accessibility and paste simulation behavior
- Accidental network access or telemetry
- Data loss or leakage through logs, crashes, or exported files

## Supported Versions

Security fixes are applied to the latest public version of ClipStash.
