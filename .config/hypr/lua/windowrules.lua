-- ============================================================================
-- Window rules + layer rules
-- ============================================================================

-- Main apps -> workspace placement
hl.window_rule({ match = { class = "firefox" },         workspace = "1" })
hl.window_rule({ match = { class = "^([Ss]potify)$" },  workspace = "2" })
hl.window_rule({ match = { class = "steam" },           workspace = "3" })
hl.window_rule({ match = { xdg_tag = "proton-game" },   workspace = "6" })
-- DP-2 (rotated to 1440x2560 portrait) hosts workspace 5 with Steam Friends on
-- top and Discord on bottom. Kept tiled (not floating) so dwindle reflows them
-- when waybar's fullscreen-mode bar reserves the top 36px during gaming.
hl.window_rule({ match = { class = "steam", title = "Friends List" }, workspace = "5" })
hl.window_rule({ match = { class = "discord" },                       workspace = "5" })

-- Whenever a Friends List window opens (boot, re-open, after Steam Big Picture
-- closes, etc.), swap it upward so it always claims the master (top) slot.
-- If there's nothing above it (Friends is already top), Hyprland just logs
-- "No window to swap with in that direction" and the bind is a no-op.
hl.on("window.open", function(w)
    if w and w.class == "steam" and w.title == "Friends List" then
        hl.dispatch(hl.dsp.window.swap({ direction = "u", window = "address:" .. w.address }))
    end
end)
hl.window_rule({ match = { class = "steam", initial_title = "^(Steam Big Picture Mode)$" }, workspace = "6", fullscreen = true })
hl.window_rule({ match = { class = "steam_app_.*" },    workspace = "4" })
-- Games launched directly via Steam (no waylandgame.sh wrapper) come up
-- windowed/floating; fullscreen them on ws 4. Digits-only so steam_app_default
-- (the Battle.net tray window handled further down) isn't caught.
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, fullscreen = true })
-- Best-effort: if such a game spawns/respawns a floating surface (e.g. some
-- titles recreate the window on a mode change), center it instead of letting
-- it land top-left off-screen. Only fires at map time, so a same-surface
-- un-fullscreen (quit-to-title on some games) won't be caught.
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, center = true })

-- Idle inhibit
hl.window_rule({ match = { class = "^(.*celluloid.*)$|^(.*mpv.*)$|^(.*vlc.*)$" }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { class = "^(.*[Ss]potify.*)$" }, idle_inhibit = "fullscreen" })
hl.window_rule({
    match        = { class = "^(.*LibreWolf.*)$|^(.*floorp.*)$|^(.*brave-browser.*)$|^(.*firefox.*)$|^(.*chromium.*)$|^(.*zen.*)$|^(.*vivaldi.*)$" },
    idle_inhibit = "fullscreen",
})

-- Picture-in-picture
hl.window_rule({
    match              = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float              = true,
    keep_aspect_ratio  = true,
    pin                = true,
    move               = {"monitor_w*0.73", "monitor_h*0.72"},
    size               = {"monitor_w*0.25", "monitor_h*0.25"},
})

-- Opacity rules: "<active> override <inactive> override <fullscreen> override"
hl.window_rule({ match = { class = "^(firefox)$" },                   opacity = "0.98 override 0.9 override 1.0 override" })
hl.window_rule({ match = { class = "^(code-oss)$" },                  opacity = "0.98 override 0.9 override 1.0 override" })
hl.window_rule({ match = { class = "^([Cc]ode)$" },                   opacity = "0.98 override 0.9 override 1.0 override" })
hl.window_rule({ match = { class = "^(code-url-handler)$" },          opacity = "0.98 override 0.9 override 1.0 override" })
hl.window_rule({ match = { class = "^(code-insiders-url-handler)$" }, opacity = "0.98 override 0.8 override 1.0 override" })
hl.window_rule({ match = { class = "^(kitty)$" },                     opacity = "0.98 override 0.8 override 1.0 override" })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$" },           opacity = "0.98 override 0.8 override 1.0 override" })

-- Floated + opacity apps
hl.window_rule({ match = { class = "^(org.kde.ark)$" },                              float = true, opacity = "0.98 override 0.8 override 1.0 override" })
hl.window_rule({ match = { class = "^(nwg-look)$" },                                 float = true, opacity = "0.98 override 0.8 override 1.0 override" })
hl.window_rule({ match = { class = "^(qt5ct)$" },                                    float = true, opacity = "0.98 override 0.8 override 1.0 override" })
hl.window_rule({ match = { class = "^(qt6ct)$" },                                    float = true, opacity = "0.98 override 0.8 override 1.0 override" })
hl.window_rule({ match = { class = "^(kvantummanager)$" },                           float = true, opacity = "0.98 override 0.8 override 1.0 override" })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" },               float = true, opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { class = "^(blueman-manager)$" },                          float = true, opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { class = "^(nm-applet)$" },                                float = true, opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" },                     float = true, opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true, opacity = "0.98 override 0.7 override 1.0 override" })

-- Authentication agents / portals
hl.window_rule({ match = { class = "^(polkit-gnome-authentication-agent-1)$" },        opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.gtk)$" },    opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.hyprland)$" }, opacity = "0.98 override 0.7 override 1.0 override" })

-- Steam & Spotify
hl.window_rule({ match = { class = "^([Ss]team)$" },           opacity = "0.99 override 0.7 override 1.0 override" })
hl.window_rule({ match = { title = "^(Steam Settings)$" },     float = true })
hl.window_rule({ match = { class = "^(steamwebhelper)$" },     opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { class = "^([Ss]potify)$" },         opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { initial_title = "^(Spotify Free)$" },    opacity = "0.98 override 0.7 override 1.0 override" })
hl.window_rule({ match = { initial_title = "^(Spotify Premium)$" }, opacity = "0.98 override 0.7 override 1.0 override" })

-- Electron / GTK apps
hl.window_rule({ match = { class = "^(com.github.rafostar.Clapper)$" },  float = true, opacity = "0.98 override 0.9 override" })
hl.window_rule({ match = { class = "^(com.github.tchx84.Flatseal)$" },   opacity = "0.98 override 0.8 override" })
hl.window_rule({ match = { class = "^(hu.kramo.Cartridges)$" },          opacity = "0.98 override 0.8 override" })
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" },        opacity = "0.98 override 0.8 override" })
hl.window_rule({ match = { class = "^(gnome-boxes)$" },                  opacity = "0.98 override 0.8 override" })
hl.window_rule({ match = { class = "^(vesktop)$" },                      opacity = "0.98 override 0.8 override" })
hl.window_rule({ match = { class = "^(discord)$" },                      opacity = "0.98 override 0.8 override" })
hl.window_rule({ match = { class = "^(WebCord)$" },                      opacity = "0.98 override 0.8 override" })
hl.window_rule({ match = { class = "^(ArmCord)$" },                      opacity = "0.98 override 0.8 override" })

-- Dolphin dialogs
hl.window_rule({ match = { class = "^(org.kde.dolphin)$", title = "^(Progress Dialog — Dolphin)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$", title = "^(Copying — Dolphin)$" },         float = true })

-- Firefox utils
hl.window_rule({ match = { title = "About Mozilla Firefox" },                 float = true })
hl.window_rule({ match = { title = "^(Extension: \\(Bitwarden.*)$" },         float = true })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Library)$" },    float = true })

-- Terminal monitor tools
hl.window_rule({ match = { class = "^(kitty)$", title = "^(top)$" },  float = true })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(btop)$" }, float = true })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(htop)$" }, float = true })

-- Media & viewers
hl.window_rule({ match = { class = "^(vlc)$" }, float = true })
hl.window_rule({ match = { class = "^(eog)$" }, float = true })
hl.window_rule({ match = { class = "^(com.github.unrud.VideoDownloader)$" }, float = true })

-- Screenshot annotation (satty) + nwg-displays - HyDE base had these as
-- float-only rules; replicated here with the same opacity scheme as the other
-- floating utility apps (qt5ct, nwg-look, pavucontrol, etc.).
hl.window_rule({ match = { class = "^(com.gabm.satty)$" }, float = true, opacity = "0.98 override 0.8 override 1.0 override" })
hl.window_rule({ match = { class = "^(nwg-displays)$" },   float = true, opacity = "0.98 override 0.8 override 1.0 override" })

-- Generic file dialogs / pickers
hl.window_rule({ match = { title = "^(Open)$" },                    float = true })
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true })
hl.window_rule({ match = { initial_title = "^(Open File)$" },       float = true })
hl.window_rule({ match = { title = "^(Choose Files)$" },            float = true })
hl.window_rule({ match = { title = "^(Save As)$" },                 float = true })
hl.window_rule({ match = { title = "^(Confirm to replace files)$" }, float = true })
hl.window_rule({ match = { title = "^(File Operation Progress)$" }, float = true })
hl.window_rule({ match = { class = "^([Xx]dg-desktop-portal-gtk)$" }, float = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" },         float = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" },    float = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" },             float = true })
hl.window_rule({ match = { class = "^(.*dialog.*)$" },              float = true })
hl.window_rule({ match = { title = "^(.*dialog.*)$" },              float = true })

-- WoW background render workarounds
hl.window_rule({ match = { class = "^(wowclassic.exe)$" }, keep_aspect_ratio    = true })
hl.window_rule({ match = { class = "^(wowclassic.exe)$" }, render_unfocused     = true })
hl.window_rule({ match = { class = "^(wowclassic.exe)$" }, idle_inhibit         = "always" })
hl.window_rule({ match = { class = "^(wowclassic.exe)$" }, workspace            = "4 silent" })
hl.window_rule({ match = { class = "^(wowclassic.exe)$" }, no_shortcuts_inhibit = true })

-- Battle.net tray window
hl.window_rule({ match = { class = "^(steam_app_default)$", title = "^$" }, opacity  = "0 override" })
hl.window_rule({ match = { class = "^(steam_app_default)$", title = "^$" }, no_focus = true })

-- Screensaver
hl.window_rule({ match = { class = "^(matrix_screensaver)$" },      fullscreen = true, no_initial_focus = true })
hl.window_rule({ match = { class = "^(matrix_screensaver_DP-1)$" }, monitor = "DP-1" })
hl.window_rule({ match = { class = "^(matrix_screensaver_DP-2)$" }, monitor = "DP-2" })

-- Layer rules
hl.layer_rule({ name = "layerrule-1", match = { namespace = "waybar" },                     ignore_alpha = 0 })
hl.layer_rule({ name = "layerrule-2", match = { namespace = "rofi" },                       blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "layerrule-3", match = { namespace = "notifications" },              blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "layerrule-4", match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "layerrule-5", match = { namespace = "swaync-control-center" },      blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "layerrule-6", match = { namespace = "logout_dialog" },              blur = true })
