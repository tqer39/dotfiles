------------------------------------------------------------
-- Ctrl+Shift+← で左 50 %
-- 直後（0.5 秒以内）に Ctrl+Shift+↑ で左上 25 %
------------------------------------------------------------
local mod        = {"ctrl", "cmd"} -- ⌘⌃
local SEQ_LIMIT  = 0.75        -- 連続入力の猶予秒
local lastDir, ts = nil, 0

local function frame(win, x, y, w, h) win:setFrame{ x=x, y=y, w=w, h=h } end

-- 左半分 1/2
hs.hotkey.bind(mod, "Left", function()
  local win = hs.window.focusedWindow(); if not win then return end
  if lastDir == "up" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w/2, scr.h/2)
    hs.alert.show("↖ 左上 1/4")          -- デバッグ表示
    lastDir = "upleft"
  elseif lastDir == "down" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y + scr.h/2, scr.w/2, scr.h/2)
    hs.alert.show("↙ 左下 1/4")          -- デバッグ表示
    lastDir = "downleft"
  elseif lastDir == "upleft" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↖ 左上 1/8 [0]")      -- デバッグ表示
    lastDir = "upleft8_0"
  elseif lastDir == "downleft" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↙ 左下 1/8 [4]")      -- デバッグ表示
    lastDir = "downleft8_4"
  elseif lastDir == "upright8_1" then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↖ 左上 1/8 [0]")      -- デバッグ表示
    lastDir = "upleft8_0"
  elseif lastDir == "upright8_3" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↗ 右上 1/8 [2]")      -- デバッグ表示
    lastDir = "upright8_2"
  elseif lastDir == "downright8_5" then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↙ 左下 1/8 [4]")      -- デバッグ表示
    lastDir = "downleft8_4"
  elseif lastDir == "downright8_7" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↘ 右下 1/8 [6]")      -- デバッグ表示
    lastDir = "downright8_6"
  elseif lastDir == "upright" then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w, scr.h/2)
    hs.alert.show("↑ 上 1/2")            -- デバッグ表示
    lastDir, ts = "up", hs.timer.secondsSinceEpoch()
  elseif lastDir == "downright" then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y + scr.h/2, scr.w, scr.h/2)
    hs.alert.show("↓ 下 1/2")            -- デバッグ表示
    lastDir, ts = "down", hs.timer.secondsSinceEpoch()
  else
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w/2, scr.h)
    hs.alert.show("← 左 1/2")              -- デバッグ表示
    lastDir, ts = "left", hs.timer.secondsSinceEpoch()
  end
end)

-- 右半分 1/2
hs.hotkey.bind(mod, "Right", function()
  local win = hs.window.focusedWindow(); if not win then return end
  if lastDir == "up" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y, scr.w/2, scr.h/2)
    hs.alert.show("↗ 右上 1/4")          -- デバッグ表示
    lastDir = "upright"
  elseif lastDir == "down" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y + scr.h/2, scr.w/2, scr.h/2)
    hs.alert.show("↘ 右下 1/4")          -- デバッグ表示
    lastDir = "downright"
  elseif lastDir == "upright" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w*3/4, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↗ 右上 1/8 [3]")      -- デバッグ表示
    lastDir = "upright8_3"
  elseif lastDir == "downright" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w*3/4, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↘ 右下 1/8 [7]")      -- デバッグ表示
    lastDir = "downright8_7"
  elseif lastDir == "upleft8_0" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/4, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↗ 右上 1/8 [1]")      -- デバッグ表示
    lastDir = "upright8_1"
  elseif lastDir == "upright8_2" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w*3/4, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↗ 右上 1/8 [3]")      -- デバッグ表示
    lastDir = "upright8_3"
  elseif lastDir == "downleft8_4" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/4, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↘ 右下 1/8 [5]")      -- デバッグ表示
    lastDir = "downright8_5"
  elseif lastDir == "downright8_6" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w*3/4, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↘ 右下 1/8 [7]")      -- デバッグ表示
    lastDir = "downright8_7"
  elseif lastDir == "upleft" then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w, scr.h/2)
    hs.alert.show("↑ 上 1/2")            -- デバッグ表示
    lastDir, ts = "up", hs.timer.secondsSinceEpoch()
  elseif lastDir == "downleft" then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y + scr.h/2, scr.w, scr.h/2)
    hs.alert.show("↓ 下 1/2")            -- デバッグ表示
    lastDir, ts = "down", hs.timer.secondsSinceEpoch()
  else
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y, scr.w/2, scr.h)
    hs.alert.show("→ 右 1/2")              -- デバッグ表示
    lastDir, ts = "right", hs.timer.secondsSinceEpoch()
  end
end)

-- 上 1/2
hs.hotkey.bind(mod, "Up", function()
  local win = hs.window.focusedWindow(); if not win then return end
  if lastDir == "left" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w/2, scr.h/2)
    hs.alert.show("↖ 左上 1/4")          -- デバッグ表示
    lastDir = "upleft"
  elseif lastDir == "right" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y, scr.w/2, scr.h/2)
    hs.alert.show("↗ 右上 1/4")          -- デバッグ表示
    lastDir = "upright"
  elseif lastDir == "downleft8_4" then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↖ 左上 1/8 [0]")      -- デバッグ表示
    lastDir = "upleft8_0"
  elseif lastDir == "downright8_5" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/4, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↗ 右上 1/8 [1]")      -- デバッグ表示
    lastDir = "upright8_1"
  elseif lastDir == "downright8_6" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↗ 右上 1/8 [2]")      -- デバッグ表示
    lastDir = "upright8_2"
  elseif lastDir == "downright8_7" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w*3/4, scr.y, scr.w/4, scr.h/2)
    hs.alert.show("↗ 右上 1/8 [3]")      -- デバッグ表示
    lastDir = "upright8_3"
  else
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y, scr.w, scr.h/2)
    hs.alert.show("↑ 上 1/2")            -- デバッグ表示
    lastDir, ts = "up", hs.timer.secondsSinceEpoch()
  end
end)

-- 下 1/2
hs.hotkey.bind(mod, "Down", function()
  local win = hs.window.focusedWindow(); if not win then return end
  if lastDir == "left" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y + scr.h/2, scr.w/2, scr.h/2)
    hs.alert.show("↙ 左下 1/4")          -- デバッグ表示
    lastDir = "downleft"
  elseif lastDir == "right" and (hs.timer.secondsSinceEpoch() - ts) < SEQ_LIMIT then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y + scr.h/2, scr.w/2, scr.h/2)
    hs.alert.show("↘ 右下 1/4")          -- デバッグ表示
    lastDir = "downright"
  elseif lastDir == "upleft8_0" then
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↙ 左下 1/8 [4]")      -- デバッグ表示
    lastDir = "downleft8_4"
  elseif lastDir == "upright8_1" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/4, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↘ 右下 1/8 [5]")      -- デバッグ表示
    lastDir = "downright8_5"
  elseif lastDir == "upright8_2" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↘ 右下 1/8 [6]")      -- デバッグ表示
    lastDir = "downright8_6"
  elseif lastDir == "upright8_3" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w*3/4, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↘ 右下 1/8 [7]")      -- デバッグ表示
    lastDir = "downright8_7"
  elseif lastDir == "down" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/2, scr.y + scr.h/2, scr.w/2, scr.h/2)
    hs.alert.show("↘ 右下 1/4")          -- デバッグ表示
    lastDir = "downright"
  elseif lastDir == "downright" then
    local scr = win:screen():frame()
    frame(win, scr.x + scr.w/4, scr.y + scr.h/2, scr.w/4, scr.h/2)
    hs.alert.show("↘ 右下 1/8 [5]")      -- デバッグ表示
    lastDir = "downright8_5"
  else
    local scr = win:screen():frame()
    frame(win, scr.x, scr.y + scr.h/2, scr.w, scr.h/2)
    hs.alert.show("↓ 下 1/2")            -- デバッグ表示
    lastDir, ts = "down", hs.timer.secondsSinceEpoch()
  end
end)

-- 設定の自動リロード
hs.loadSpoon("ReloadConfiguration")   -- Spoon をロード
spoon.ReloadConfiguration:start()     -- 自動監視スタート
spoon.ReloadConfiguration:bindHotkeys({
  reload = { {"cmd","ctrl","shift"}, "R" }  -- ⌘⌃⇧R で手動リロード
})
