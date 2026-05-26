-- ============================================================================
-- Environment variables (merged from old hyprland.conf, userprefs.conf, nvidia.conf)
-- ============================================================================

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("ELECTRON_ENABLE_WAYLAND",      "1")
hl.env("XCURSOR_THEME",                "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE",                 "16")
hl.env("HYPRCURSOR_THEME",             "bibata-modern-ice")
hl.env("HYPRCURSOR_SIZE",              "16")
hl.env("LIBVA_DRIVER_NAME",            "nvidia")
hl.env("NVD_BACKEND",                  "direct")
hl.env("__GLX_VENDOR_LIBRARY_NAME",    "nvidia")
hl.env("XDG_SESSION_TYPE",             "wayland")
hl.env("XDG_MENU_PREFIX",              "arch-")
hl.env("XDG_CURRENT_DESKTOP",          "Hyprland")
hl.env("WLR_NO_HARDWARE_CURSORS",      "1")
hl.env("WLR_DRM_NO_MODIFIERS",         "1")
hl.env("QT_QPA_PLATFORMTHEME",         "qt5ct")
hl.env("GDK_BACKEND",                  "wayland,x11")

-- Point ssh + git at the systemd user ssh-agent.socket (enabled via
-- `systemctl --user enable --now ssh-agent.socket`).
hl.env("SSH_AUTH_SOCK",                os.getenv("XDG_RUNTIME_DIR") .. "/ssh-agent.socket")
