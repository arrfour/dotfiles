local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Shell detection logic
local function get_default_shell()
  local shells = { '/bin/zsh', '/usr/bin/zsh', '/bin/fish', '/usr/bin/fish', '/bin/bash', '/usr/bin/bash' }
  for _, shell in ipairs(shells) do
    local f = io.open(shell, "r")
    if f ~= nil then
      io.close(f)
      return shell
    end
  end
  return '/bin/bash'
end

config.default_prog = { get_default_shell() }

-- Appearance & Behavior
config.color_scheme = 'Builtin Solarized Dark'
config.font = wezterm.font 'RobotoMono Nerd Font'
config.font_size = 11.0
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 5000

-- Platform specific adjustments
if wezterm.target_triple:find("apple") then
  config.font_size = 13.0
end

return config
