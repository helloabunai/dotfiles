-- ============================================================================
-- Autostart: services + apps to launch on Hyprland start
-- ============================================================================

local v = require("lua.vars")
local HOME    = v.HOME
local scrPath = v.scrPath
local userScr = v.userScr

hl.on("hyprland.start", function()
    -- HyDE essential services (replicated from ~/.local/share/hyde/hyprland.conf)
    hl.exec_cmd(scrPath .. "/resetxdgportal.sh")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Boot waybar in 'normal' layout (DP-1 + HDMI-A-1 only). config.jsonc is
    -- kept chmod 444 so waybar.py can't restore the HyDE layout default ("*").
    -- gamescope.sh / waylandgame.sh use the same chmod-+w/cp/-w pattern to swap
    -- to/from the fullscreen variant; this guards against a partial restore.
    hl.exec_cmd("chmod +w " .. HOME .. "/.config/waybar/config.jsonc 2>/dev/null; "
                .. "cp -f " .. HOME .. "/.config/waybar/config-normal.jsonc "
                            .. HOME .. "/.config/waybar/config.jsonc; "
                .. "chmod -w " .. HOME .. "/.config/waybar/config.jsonc; "
                .. scrPath .. "/waybar.py --watch --update")

    hl.exec_cmd("dunst")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("ssh-add " .. HOME .. "/.ssh/github")
    hl.exec_cmd(scrPath .. "/batterynotify.sh")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("udiskie --no-automount --smart-tray")
    hl.exec_cmd(scrPath .. "/polkitkdeauth.sh")
    hl.exec_cmd("hypridle")

    -- From hyprland.conf
    hl.exec_cmd("/usr/bin/bash " .. userScr .. "/wall.sh")
    hl.exec_cmd(userScr .. "/virtual_monitor.sh")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("xrdb -merge ~/.Xresources")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 16")

    -- From monitors.conf
    hl.exec_cmd("/usr/bin/bash " .. userScr .. "/remote_cleanup.sh")

    -- From userprefs.conf
    hl.exec_cmd("firefox")
    hl.exec_cmd("steam")
    hl.exec_cmd("sh -c 'sleep 10 && steam steam://open/friends'")
    hl.exec_cmd("spotify")
    hl.exec_cmd("sunshine")
    hl.exec_cmd("tailscale")
    hl.exec_cmd("xmousepasteblock")
    hl.exec_cmd("discord --ozone-platform=x11")
    hl.exec_cmd("sh -c 'sleep 10 && bluetoothctl power on'")
    hl.exec_cmd("rm ~/.cache/idle_inhibitor_status")
    hl.exec_cmd("/usr/bin/bash " .. userScr .. "/nfs_prewarm.sh")
    hl.exec_cmd("xembedsniproxy")
end)
