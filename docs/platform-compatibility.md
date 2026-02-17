# Platform Compatibility

[🇯🇵 日本語版](./platform-compatibility.ja.md)

This document describes tool availability and alternatives across macOS, Linux, and Windows.

## CLI Tools

| Tool | macOS | Ubuntu/Mint | Windows | Notes |
| ---- | :---: | :---------: | :-----: | ----- |
| zsh | Brew | Brew/apt | N/A | Windows uses PowerShell |
| starship | Brew | Brew | Scoop | Cross-platform prompt |
| git | Brew | Brew/apt | Scoop | |
| gh | Brew | Brew | Scoop | GitHub CLI |
| eza | Brew | Brew | Scoop | Modern ls replacement |
| bat | Brew | Brew | Scoop | Modern cat replacement |
| fzf | Brew | Brew/apt | Scoop | Fuzzy finder |
| ripgrep | Brew | Brew/apt | Scoop | Modern grep replacement |
| jq | Brew | Brew/apt | Scoop | JSON processor |
| direnv | Brew | Brew | N/A | Environment switcher |
| mise | Brew | Brew | Scoop | Tool version manager |
| awscli | Brew | Brew | winget | AWS CLI |

## GUI Applications

| Application | macOS | Ubuntu | Mint | Windows | Notes |
| ----------- | :---: | :----: | :--: | :-----: | ----- |
| VS Code | Cask | apt | apt | winget | |
| 1Password | Cask | apt | apt | winget | |
| Raycast | Cask | N/A | N/A | winget | Launcher |
| VLC | Cask | apt | apt | N/A | Media player |
| Ghostty | Cask | snap | flatpak | N/A | Terminal emulator |
| Spotify | Cask | snap | flatpak | N/A | Music player |

## macOS Only (No Alternatives)

These tools have no equivalent on other platforms:

| Tool | Purpose | Reason |
| ---- | ------- | ------ |
| Karabiner-Elements | Keyboard remapping | Requires macOS keyboard APIs |
| Hammerspoon | Window management | macOS Lua scripting bridge |
| Ghostty | Terminal emulator | No Windows build available |

## Platform-Specific Alternatives

| Feature | macOS | Ubuntu/Mint | Windows |
| ------- | ----- | ----------- | ------- |
| Launcher | Raycast | Albert | Raycast |
| Terminal | Ghostty | Ghostty (snap/flatpak) | MobaXterm |
| Clipboard CLI | pbcopy/pbpaste | xsel/xclip | clip.exe |
| Keyboard remap | Karabiner | N/A | N/A |
| Window management | Hammerspoon | N/A | N/A |

## Package Managers

| Platform | Primary | Secondary | Notes |
| -------- | ------- | --------- | ----- |
| macOS | Homebrew | - | |
| Ubuntu | Homebrew | apt | snap for GUI apps |
| Mint | Homebrew | apt | flatpak for GUI apps (snap disabled by default) |
| Windows | Scoop | winget | |

Windows uses Scoop for CLI tools (user-space, no admin required) and winget for GUI applications.
Mint uses flatpak instead of snap for GUI applications (Ghostty, Spotify) as snap is disabled by default.
