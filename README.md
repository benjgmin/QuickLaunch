# QuickLaunch

A lightweight, keyboard-driven launcher for macOS, built with SwiftUI and AppKit. Think Spotlight or Raycast, stripped down to the stuff I actually use every day.

Hit `⌘⇧Space` from anywhere, type, hit enter.

<!-- Add a demo gif here, e.g. ![demo](docs/demo.gif) -->

## Features

- **App & file launcher** — finds `.app` bundles plus scripts and executables (`.command`, `.sh`, `.py`, etc.), with fuzzy matching
- **Spotlight integration** — falls back to `mdfind` to find files anywhere in your home folder when the local cache comes up short
- **Calculator** — `=` prefix for instant math, including `sqrt()`
- **Web search** — jump straight to Google, YouTube, GitHub, or a dictionary lookup
- **Clipboard history** — last 20 copied items, one keystroke to re-copy
- **Emoji picker** — search by name or keyword, copies to clipboard
- **System commands** — lock, sleep, screenshot, toggle dark mode, empty trash, and more
- **Recent items** — remembers what you launched last, persists across restarts
- Lives in the menu bar, closes automatically when you click away

## Usage

| Prefix | Mode | Example |
|---|---|---|
| *(none)* | Apps & files | `safari`, `lilith` |
| `=` | Calculator | `=100*0.15` |
| `g` | Google | `g swift concurrency` |
| `yt` | YouTube | `yt lofi` |
| `gh` | GitHub | `gh swiftui` |
| `def` | Define a word | `def ephemeral` |
| `cb` | Clipboard history | `cb` |
| `:` | Emoji | `:fire` |
| `>` | System commands | `>lock` |

`↑` / `↓` to navigate, `↵` to select, `esc` to close.

## How it works

- **Global hotkey** is registered through the Carbon Event Manager (`RegisterEventHotKey`), so it fires even when the app isn't focused.
- **Search** runs in two layers: an in-memory index built at launch (apps from `/Applications`, `/System/Applications`, and executables in common user folders), scored by exact / prefix / substring / fuzzy match. If that returns fewer than 5 hits, it queries Spotlight via `mdfind` with a case-insensitive `kMDItemFSName` predicate.
- **Clipboard history** polls `NSPasteboard` on a timer.
- **Calculator** evaluates expressions with `bc`.
- **UI** is SwiftUI hosted in a borderless, floating `NSWindow` that joins all Spaces and hides on `didResignKey`.

## Building

Requirements: macOS 14+, Xcode 15+

```bash
git clone https://github.com/YOURUSERNAME/QuickLaunch.git
cd QuickLaunch
open QuickLaunch.xcodeproj
```

Then build and run with `⌘R`.

> **Note:** App Sandbox is disabled on purpose. A sandboxed build can only see its own container, so file search and launching scripts won't work. This also means QuickLaunch isn't App Store-eligible.

To quit, click the magnifying glass in the menu bar → **Quit QuickLaunch**.

## Project structure

```
QuickLaunch/
├── QuickLaunchApp.swift    # App delegate, menu bar item, hotkey, window management
├── SearchViewModel.swift   # Search logic, indexing, Spotlight queries, clipboard monitor
├── ContentView.swift       # Main search UI
├── Components.swift        # Row views, headers, key handling
└── Models.swift            # AppInfo, ClipboardItem, SearchMode, etc.
```

## Roadmap

- [ ] Move Spotlight queries off the main thread with debounced async search
- [ ] Configurable hotkey
- [ ] Persist clipboard history
- [ ] Custom web search engines
- [ ] Launch at login

## License

MIT
