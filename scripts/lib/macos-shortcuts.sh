#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# macos-shortcuts.sh - macOS のシステムショートカットの調整
# ------------------------------------------------------------------------------

MACOS_ACTIVATE_SETTINGS="${MACOS_ACTIVATE_SETTINGS:-/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings}"

# ID 27「次のウインドウを操作対象にする」を無効にする。
# Why: 日本語環境の既定値 ⌘@ は keycode 33 で、US 配列では [ の位置にあたる。
# macOS は Shift 付きを「前のウインドウ」として取るため、Orca・Codex の
# 前のタブ（Cmd+Shift+[）がアプリに届かない。parameters は既定値のまま残す。
MACOS_NEXT_WINDOW_HOTKEY_ID=27
MACOS_NEXT_WINDOW_HOTKEY_DISABLED='<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>64</integer><integer>33</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'

configure_macos_shortcuts() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY RUN] Would disable macOS shortcut: Move focus to next window (ID ${MACOS_NEXT_WINDOW_HOTKEY_ID})"
    return 0
  fi

  log_info "Disabling macOS shortcut: Move focus to next window (ID ${MACOS_NEXT_WINDOW_HOTKEY_ID})"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add \
    "$MACOS_NEXT_WINDOW_HOTKEY_ID" "$MACOS_NEXT_WINDOW_HOTKEY_DISABLED"

  # 再ログインせずに反映する。失敗してもインストールは止めない。
  if [[ -x "$MACOS_ACTIVATE_SETTINGS" ]]; then
    "$MACOS_ACTIVATE_SETTINGS" -u || log_warn "Failed to reload macOS settings; log out to apply"
  fi
}
