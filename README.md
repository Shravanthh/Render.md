# Render.md

A lightweight, beautiful Markdown editor for macOS built with SwiftUI.

![Render.md](https://img.shields.io/badge/macOS-13.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 📝 **Live Preview** - See your markdown rendered in real-time
- 🎨 **Syntax Highlighting** - Editor with markdown syntax colors
- 🗂️ **Tabbed Interface** - Work with multiple files
- 📁 **Folder Browser** - Open and browse project folders
- 🌙 **Multiple Themes** - Dracula, Monokai, One Dark, GitHub Dark
- ⌨️ **Keyboard Shortcuts** - Vim-like efficiency
- 🔍 **Find & Replace** - Search within documents
- 📤 **Export** - Save as HTML or PDF
- 💾 **Auto-save** - Never lose your work
- 🖥️ **Zen Mode** - Distraction-free writing

## Screenshots

*Coming soon*

## Installation

### Download DMG (Recommended)

1. Download the latest [Render.md-1.0.0.dmg](https://github.com/Shravanthh/Render.md/releases/latest)
2. Open the DMG file
3. Drag Render.md to Applications folder
4. Launch from Applications

### Build from Source

```bash
git clone https://github.com/YOUR_USERNAME/Render.md.git
cd Render.md
swift build -c release
```

The binary will be at `.build/release/MarkdownPreview`

### Create App Bundle

```bash
./scripts/build-app.sh
```

### Create DMG Installer

```bash
./scripts/create-dmg.sh
```

The DMG will be created in the `dist/` directory.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘T | New Tab |
| ⌘W | Close Tab |
| ⌘S | Save |
| ⌘O | Open File |
| ⌘P | Toggle Preview |
| ⌘F | Find |
| ⌘⇧P | Command Palette |
| ⌘⇧Z | Zen Mode |
| ⌘+ | Increase Font |
| ⌘- | Decrease Font |

## Project Structure

```
MarkdownPreview/
├── App/           # App entry point & delegate
├── Models/        # Data models (Tab, Theme)
├── ViewModels/    # State management
├── Views/         # Main views
├── Components/    # Reusable UI components
├── Services/      # Business logic
└── Extensions/    # Swift extensions
```

## Requirements

- macOS 13.0+
- Swift 5.9+

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please read the contributing guidelines first.

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request
