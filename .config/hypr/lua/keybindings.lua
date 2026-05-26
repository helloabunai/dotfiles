-- ============================================================================
-- Keybindings
-- ============================================================================

local v = require("lua.vars")
local mainMod    = v.mainMod
local TERMINAL   = v.TERMINAL
local BROWSER    = v.BROWSER
local EXPLORER   = v.EXPLORER
local scrPath    = v.scrPath
local userScr    = v.userScr
local moveActiveOrDirection = v.moveActiveOrDirection

-- ---- Window Management ----
hl.bind(mainMod         .. " + Q",      hl.dsp.exec_cmd(scrPath .. "/dontkillsteam.sh"), { description = "[Window Management] close focused window" })
hl.bind("ALT + F4",                     hl.dsp.exec_cmd(scrPath .. "/dontkillsteam.sh"), { description = "[Window Management] close focused window" })
hl.bind(mainMod         .. " + Delete", hl.dsp.exit(),                                    { description = "[Window Management] kill hyprland session" })
hl.bind(mainMod         .. " + W",      hl.dsp.window.float({ action = "toggle" }),       { description = "[Window Management] Toggle floating" })
hl.bind(mainMod         .. " + G",      hl.dsp.group.toggle(),                            { description = "[Window Management] toggle group" })
hl.bind(mainMod         .. " + F",      hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod         .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod         .. " + L",      hl.dsp.exec_cmd(userScr .. "/screensaver.sh start"), { description = "[Window Management] lock screen" })
hl.bind("CONTROL + ALT + Delete",       hl.dsp.exec_cmd(scrPath .. "/logoutlaunch.sh"),  { description = "[Window Management] logout menu" })
hl.bind("ALT_R + CONTROL_R",            hl.dsp.exec_cmd("hyde-shell waybar --hide"),     { description = "[Window Management] toggle waybar and reload config" })

-- ---- Group Navigation ----
hl.bind(mainMod .. " + CONTROL + H", hl.dsp.group.prev(), { description = "[Window Management|Group Navigation] change active group backwards" })
hl.bind(mainMod .. " + CONTROL + L", hl.dsp.group.next(), { description = "[Window Management|Group Navigation] change active group forwards" })

-- ---- Change focus ----
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }), { description = "[Window Management|Change focus] focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }), { description = "[Window Management|Change focus] focus right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }), { description = "[Window Management|Change focus] focus up" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }), { description = "[Window Management|Change focus] focus down" })
hl.bind("ALT + Tab",           hl.dsp.window.cycle_next(),        { description = "[Window Management|Change focus] Cycle focus" })

-- ---- Resize active window ----
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x =  30, y =   0, relative = true }), { description = "[Window Management|Resize Active Window] resize window right", repeating = true })
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -30, y =   0, relative = true }), { description = "[Window Management|Resize Active Window] resize window left",  repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x =   0, y = -30, relative = true }), { description = "[Window Management|Resize Active Window] resize window up",    repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x =   0, y =  30, relative = true }), { description = "[Window Management|Resize Active Window] resize window down",  repeating = true })

-- ---- Move active window across workspace (floating delta, else tiled move) ----
hl.bind(mainMod .. " + SHIFT + CONTROL + left",  moveActiveOrDirection(-30,   0, "l"), { description = "[Window Management|Move active window across workspace] Move active window to the left",  repeating = true })
hl.bind(mainMod .. " + SHIFT + CONTROL + right", moveActiveOrDirection( 30,   0, "r"), { description = "[Window Management|Move active window across workspace] Move active window to the right", repeating = true })
hl.bind(mainMod .. " + SHIFT + CONTROL + up",    moveActiveOrDirection(  0, -30, "u"), { description = "[Window Management|Move active window across workspace] Move active window up",            repeating = true })
hl.bind(mainMod .. " + SHIFT + CONTROL + down",  moveActiveOrDirection(  0,  30, "d"), { description = "[Window Management|Move active window across workspace] Move active window down",          repeating = true })

-- ---- Move & Resize with mouse ----
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "[Window Management|Move & Resize with mouse] hold to move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "[Window Management|Move & Resize with mouse] hold to resize window" })
hl.bind(mainMod .. " + Z",         hl.dsp.window.drag(),   { mouse = true, description = "[Window Management|Move & Resize with mouse] hold to move window" })
hl.bind(mainMod .. " + X",         hl.dsp.window.resize(), { mouse = true, description = "[Window Management|Move & Resize with mouse] hold to resize window" })

-- ---- Toggle split ----
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "[Window Management] toggle split" })

-- ---- Launcher: Apps ----
hl.bind(mainMod .. " + T",       hl.dsp.exec_cmd(TERMINAL), { description = "[Launcher|Apps] terminal emulator" })
hl.bind(mainMod .. " + ALT + T", hl.dsp.exec_cmd("[float; move 20% 5%; size 60% 60%] " .. TERMINAL), { description = "[Launcher|Apps] dropdown terminal" })
hl.bind(mainMod .. " + E",       hl.dsp.exec_cmd(EXPLORER), { description = "[Launcher|Apps] file explorer" })
hl.bind(mainMod .. " + B",       hl.dsp.exec_cmd(BROWSER),  { description = "[Launcher|Apps] web browser" })
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(scrPath .. "/sysmonlaunch.sh"), { description = "[Launcher|Apps] system monitor" })
hl.bind("ALT + a", hl.dsp.exec_cmd(userScr .. "/waybar_refresh.sh"))

-- ---- Launcher: Rofi menus ----
local rofiLaunch = scrPath .. "/rofilaunch.sh"
hl.bind(mainMod .. " + SPACE",    hl.dsp.exec_cmd("pkill -x rofi || " .. rofiLaunch .. " d"), { description = "[Launcher|Rofi menus] application finder" })
hl.bind(mainMod .. " + TAB",      hl.dsp.exec_cmd("pkill -x rofi || " .. rofiLaunch .. " w"), { description = "[Launcher|Rofi menus] window switcher" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("pkill -x rofi || " .. rofiLaunch .. " f"), { description = "[Launcher|Rofi menus] file finder" })
hl.bind(mainMod .. " + slash",    hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/keybinds_hint.sh c"), { description = "[Launcher|Rofi menus] keybindings hint" })
hl.bind(mainMod .. " + comma",    hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/emoji-picker.sh"),   { description = "[Launcher|Rofi menus] emoji picker" })
hl.bind(mainMod .. " + period",   hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/glyph-picker.sh"),   { description = "[Launcher|Rofi menus] glyph picker" })
hl.bind(mainMod .. " + V",        hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/cliphist.sh -c"),    { description = "[Launcher|Rofi menus] clipboard" })
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/cliphist.sh"),      { description = "[Launcher|Rofi menus] clipboard manager" })
hl.bind(mainMod .. " + ALT + C",  hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/calculator.sh"),     { description = "[Launcher|Rofi menus] calculator" })

-- ---- Hardware Controls: Audio ----
hl.bind("F10",          hl.dsp.exec_cmd(scrPath .. "/volumecontrol.sh -o m"), { locked = true, description = "[Hardware Controls|Audio] toggle mute output" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scrPath .. "/volumecontrol.sh -o m"), { locked = true, description = "[Hardware Controls|Audio] toggle mute output" })
hl.bind("F11",          hl.dsp.exec_cmd(scrPath .. "/volumecontrol.sh -o d"), { locked = true, repeating = true, description = "[Hardware Controls|Audio] decrease volume" })
hl.bind("F12",          hl.dsp.exec_cmd(scrPath .. "/volumecontrol.sh -o i"), { locked = true, repeating = true, description = "[Hardware Controls|Audio] increase volume" })
hl.bind(mainMod .. " + mouse:275", hl.dsp.exec_cmd(scrPath .. "/volumecontrol.sh -i m"), { locked = true, description = "[Hardware Controls|Audio] un/mute microphone" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scrPath .. "/volumecontrol.sh -o d"), { locked = true, repeating = true, description = "[Hardware Controls|Audio] decrease volume" })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scrPath .. "/volumecontrol.sh -o i"), { locked = true, repeating = true, description = "[Hardware Controls|Audio] increase volume" })

-- ---- Hardware Controls: Media ----
hl.bind(mainMod .. " + SHIFT + z", hl.dsp.exec_cmd("playerctl previous"))
hl.bind(mainMod .. " + SHIFT + x", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind(mainMod .. " + SHIFT + c", hl.dsp.exec_cmd("playerctl next"))

-- ---- Hardware Controls: Brightness ----
hl.bind("ALT + up",   hl.dsp.exec_cmd("ddcutil setvcp 10 + 10"), { locked = true, repeating = true })
hl.bind("ALT + down", hl.dsp.exec_cmd("ddcutil setvcp 10 - 10"), { locked = true, repeating = true })

-- ---- Utilities ----
hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd(scrPath .. "/keyboardswitch.sh"), { locked = true, description = "[Utilities] toggle keyboard layout" })
hl.bind(mainMod .. " + ALT + G",   hl.dsp.exec_cmd(scrPath .. "/gamemode.sh"),       { description = "[Utilities] game mode" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(scrPath .. "/gamelauncher.sh"),   { description = "[Utilities] open game launcher" })

-- ---- Utilities: Screen Capture ----
hl.bind(mainMod .. " + SHIFT + P",   hl.dsp.exec_cmd("hyprpicker -an"),                       { description = "[Utilities|Screen Capture] color picker" })
hl.bind(mainMod .. " + SHIFT + S",   hl.dsp.exec_cmd(scrPath .. "/screenshot.sh s"),         { description = "[Utilities|Screen Capture] snip screen" })
hl.bind(mainMod .. " + CONTROL + P", hl.dsp.exec_cmd(scrPath .. "/screenshot.sh sf"),        { description = "[Utilities|Screen Capture] freeze and snip screen" })
hl.bind(mainMod .. " + ALT + P",     hl.dsp.exec_cmd(scrPath .. "/screenshot.sh m"),         { locked = true, description = "[Utilities|Screen Capture] print monitor" })
hl.bind("Print",                     hl.dsp.exec_cmd(scrPath .. "/screenshot.sh p"),         { locked = true, description = "[Utilities|Screen Capture] print all monitors" })

-- ---- Theming and Wallpaper ----
hl.bind(mainMod .. " + ALT + right",  hl.dsp.exec_cmd(scrPath .. "/wallpaper.sh -Gn"),                          { description = "[Theming and Wallpaper] next global wallpaper" })
hl.bind(mainMod .. " + ALT + left",   hl.dsp.exec_cmd(scrPath .. "/wallpaper.sh -Gp"),                          { description = "[Theming and Wallpaper] previous global wallpaper" })
hl.bind(mainMod .. " + SHIFT + W",    hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/wallpaper.sh -SG"),   { description = "[Theming and Wallpaper] select a global wallpaper" })
hl.bind(mainMod .. " + ALT + up",     hl.dsp.exec_cmd(scrPath .. "/wbarconfgen.sh n"),                          { description = "[Theming and Wallpaper] next waybar layout" })
hl.bind(mainMod .. " + ALT + down",   hl.dsp.exec_cmd(scrPath .. "/wbarconfgen.sh p"),                          { description = "[Theming and Wallpaper] previous waybar layout" })
hl.bind(mainMod .. " + SHIFT + R",    hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/wallbashtoggle.sh -m"), { description = "[Theming and Wallpaper] wallbash mode selector" })
hl.bind(mainMod .. " + SHIFT + T",    hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/themeselect.sh"),     { description = "[Theming and Wallpaper] select a theme" })
hl.bind(mainMod .. " + SHIFT + Y",    hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/animations.sh --select"), { description = "[Theming and Wallpaper] select animations" })
hl.bind(mainMod .. " + SHIFT + U",    hl.dsp.exec_cmd("pkill -x rofi || " .. scrPath .. "/hyprlock.sh --select"),   { description = "[Theming and Wallpaper] select hyprlock layout" })

-- ---- Workspaces: Navigation ----
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,               hl.dsp.focus({ workspace = tostring(i) }),                       { description = "[Workspaces|Navigation] navigate to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key,       hl.dsp.window.move({ workspace = tostring(i) }),                 { description = "[Workspaces|Move window to workspace] move to workspace " .. i })
    hl.bind(mainMod .. " + ALT + " .. key,         hl.dsp.window.move({ workspace = tostring(i), follow = false }), { description = "[Workspaces|Navigation|Move window silently] move to workspace " .. i .. " (silent)" })
end

hl.bind(mainMod .. " + CONTROL + right", hl.dsp.focus({ workspace = "r+1" }), { description = "[Workspaces|Navigation|Relative workspace] change active workspace forwards" })
hl.bind(mainMod .. " + CONTROL + left",  hl.dsp.focus({ workspace = "r-1" }), { description = "[Workspaces|Navigation|Relative workspace] change active workspace backwards" })
hl.bind(mainMod .. " + CONTROL + down",  hl.dsp.focus({ workspace = "empty" }), { description = "[Workspaces|Navigation] navigate to the nearest empty workspace" })

-- Move focused window to a relative workspace
hl.bind(mainMod .. " + CONTROL + ALT + right", hl.dsp.window.move({ workspace = "r+1" }), { description = "[Workspaces] move window to next relative workspace" })
hl.bind(mainMod .. " + CONTROL + ALT + left",  hl.dsp.window.move({ workspace = "r-1" }), { description = "[Workspaces] move window to previous relative workspace" })

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "[Workspaces|Navigation] next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "[Workspaces|Navigation] previous workspace" })
