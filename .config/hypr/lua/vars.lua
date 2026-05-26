-- ============================================================================
-- Shared variables and helpers
-- Required by every other module via `local v = require("lua.vars")`.
-- ============================================================================

local M = {}

M.HOME       = os.getenv("HOME")
M.scrPath    = M.HOME .. "/.local/lib/hyde"
M.userScr    = M.HOME .. "/scripts"

M.mainMod    = "SUPER"
M.TERMINAL   = "kitty"
M.BROWSER    = "hyde-launch.sh --fall firefox web-browser"
M.EXPLORER   = "hyde-launch.sh --fall dolphin file-manager"
M.EDITOR     = "hyde-launch.sh --fall code-oss text-editor"
M.LOCKSCREEN = "hyprlock"

-- moveActiveOrDirection: moves a floating window by (dx, dy); falls back to a
-- directional tiled move. Mirrors the $moveactivewindow shell var from the
-- old hyprlang keybindings.
function M.moveActiveOrDirection(dx, dy, direction)
    return function()
        local w = hl.get_active_window()
        if w and w.floating then
            hl.dispatch(hl.dsp.window.move({ x = dx, y = dy, relative = true }))
        else
            hl.dispatch(hl.dsp.window.move({ direction = direction }))
        end
    end
end

return M
