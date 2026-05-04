# ClipStash Roadmap

## Current State (v1.0)
- [x] Clipboard history tracking
- [x] Keyboard-first navigation (arrows, Enter, Cmd+1-9)
- [x] Mouse/trackpad selection
- [x] Search/filter history
- [x] Liquid glass UI
- [x] Auto-cleanup (24hr retention)
- [x] Source app tracking
- [x] Duplicate prevention
- [x] Encrypted local storage
- [x] Website download flow
- [x] Basic website hit/download tracking

---

## Near Term

### Open Source Readiness
- [ ] Public issue triage labels
- [ ] Release checklist
- [ ] GitHub Releases distribution flow
- [ ] Contributor-friendly signing/build notes

### Polish & Stability
- [ ] Menu bar icon + preferences window
- [ ] Customizable hotkey
- [ ] Adjustable history limit (currently 15 items)
- [ ] Adjustable retention period
- [ ] Launch at login option
- [ ] Pinned/favorited clips (persist beyond 24hr)

### Quality of Life
- [ ] Image/file clipboard support (not just text)
- [ ] Rich text preview
- [ ] Syntax highlighting for code snippets
- [ ] Clipboard item size indicator

---

## Medium Term

### Sync & Backup
- [ ] iCloud sync (opt-in)
- [ ] Export history to JSON/CSV
- [ ] Import from other clipboard managers

### Organization
- [ ] Manual tagging/labeling
- [ ] Collections/folders
- [ ] Multi-select and bulk actions

---

## AI Features (Future)

### Transform on Paste (High Priority)
Modify clipboard content on-the-fly before pasting:
- Clean up messy text / fix formatting
- Convert between formats (JSON ↔ TypeScript, Markdown ↔ HTML)
- Translate to another language
- Summarize long content
- Convert code between languages
- Extract structured data (parse an address, phone, etc.)

### Semantic Search
Natural language search instead of exact text matching:
- "find that API key from yesterday"
- "the address Sarah sent me"
- "code with the fetch request"

### Smart Categorization
Auto-tag clips by type:
- Code (with language detection)
- URLs
- Email addresses
- Phone numbers
- Addresses
- Credentials/secrets

### Sensitive Data Detection
Automatically detect and protect:
- API keys and tokens
- Passwords
- Credit card numbers
- SSNs and personal identifiers
- Option to auto-expire or exclude from history

### Clip Intelligence
- Summarize long clips in preview
- Combine multiple clips into one
- Suggest relevant past clips based on context
- "Smart paste" that formats based on target app

---

## Ideas / Maybe

- [ ] Universal clipboard (iOS companion app)
- [ ] Snippets library (saved templates with variables)
- [ ] Clipboard sharing (temporary links)
- [ ] Alfred/Raycast integration
- [ ] CLI tool (`clipstash paste 3`)

---

## Non-Goals
- Cloud-first architecture (privacy is core)
- Subscription model for basic features
- Windows/Linux versions (macOS-native focus)

---

*Last updated: May 2026*
