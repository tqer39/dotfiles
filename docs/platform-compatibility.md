# Platform Compatibility

[🇯🇵 日本語版](./platform-compatibility.ja.md)

This document describes tool availability and alternatives across macOS, Linux, and Windows.

## CLI Tools

| Tool | macOS | Linux | Windows | Notes |
| ---- | :---: | :---: | :-----: | ----- |
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

| Application | macOS | Linux | Windows | Notes |
| ----------- | :---: | :---: | :-----: | ----- |
| VS Code | Cask | apt | winget | |
| 1Password | Cask | apt | winget | |
| Raycast | Cask | N/A | winget | Launcher |
| VLC | Cask | apt | N/A | Media player |

## macOS Only (No Alternatives)

These tools have no equivalent on other platforms:

| Tool | Purpose | Reason |
| ---- | ------- | ------ |
| Karabiner-Elements | Keyboard remapping | Requires macOS keyboard APIs |
| Hammerspoon | Window management | macOS Lua scripting bridge |
| Ghostty | Terminal emulator | No Windows build available |

## Platform-Specific Alternatives

| Feature | macOS | Linux | Windows |
| ------- | ----- | ----- | ------- |
| Launcher | Raycast | Albert | Raycast |
| Terminal | Ghostty | Ghostty | MobaXterm |
| Clipboard CLI | pbcopy/pbpaste | xsel/xclip | clip.exe |
| Keyboard remap | Karabiner | N/A | N/A |
| Window management | Hammerspoon | N/A | N/A |

## Package Managers

| Platform | Primary | Secondary |
| -------- | ------- | --------- |
| macOS | Homebrew | - |
| Linux | Homebrew | apt |
| Windows | Scoop | winget |

Windows uses Scoop for CLI tools (user-space, no admin required) and winget for GUI applications.
