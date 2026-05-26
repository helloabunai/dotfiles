-- ============================================================================
-- Hyprland configuration entry point
--
-- Modules live in ~/.config/hypr/lua/. Each require() call gets its own scope,
-- so an error in one file won't stop the others from loading.
--
-- Legacy hyprlang configs are archived in ~/.config/hypr/legacy/ for reference.
-- ============================================================================

require("lua.env")
require("lua.monitors")
require("lua.config")
require("lua.animations")
require("lua.windowrules")
require("lua.keybindings")
require("lua.autostart")
