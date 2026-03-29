local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Theme
config.color_scheme = "Tokyo Night"

-- Font
config.font = wezterm.font("BIZ UDGothic Bold")
config.font_size = 17.0

-- Background
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20

-- Window
config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2,
}

-- Tab bar
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- Cursor
config.default_cursor_style = "BlinkingBlock"

-- Keybindings
config.keys = {
  -- fzf history search (cmd+r -> ctrl+r)
  {
    key = "r",
    mods = "SUPER",
    action = wezterm.action.SendKey({ key = "r", mods = "CTRL" }),
  },
  -- Split pane (right)
  {
    key = "[",
    mods = "SUPER",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
}

return config
