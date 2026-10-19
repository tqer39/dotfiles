-- Run with: lua tests/test-hammerspoon.lua [repository root]
-- cspell:ignore pathwatcher configdir
local root = ... or "."
local original_hs = hs
local bindings, watchers = {}, {}
local reloads = 0
hs = {
  configdir = "/tmp/hammerspoon-test",
  hotkey = { bind = function(modifiers, key, callback)
    bindings[key] = { modifiers = modifiers, callback = callback }
  end },
  reload = function() reloads = reloads + 1 end,
  pathwatcher = { new = function(path, callback)
    local watcher = { path = path, callback = callback }
    function watcher:start() self.started = true; return self end
    watchers[#watchers + 1] = watcher
    return watcher
  end },
}
local ok, err = pcall(function()
  dofile(root .. "/src/.hammerspoon/init.lua")
  assert(bindings.Left and bindings.Right and bindings.Up and bindings.Down)
  assert(bindings.R, "manual reload must be available without Spoons")
  bindings.R.callback()
  assert(reloads == 1, "manual reload must reload the configuration")
  assert(#watchers > 0, "configuration changes must be watched")
  for _, watcher in ipairs(watchers) do
    assert(watcher.started, "configuration watcher must be started")
    watcher.callback({ watcher.path .. "/init.lua" })
  end
  assert(reloads > 1, "Lua changes must reload the configuration")
end)
hs = original_hs
assert(ok, err)
print("Hammerspoon configuration regression test passed")
