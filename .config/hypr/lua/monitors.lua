-- ============================================================================
-- Monitors + workspace rules
-- ============================================================================

-- Physical monitors
hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0",      scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "2560x-520", scale = 1, transform = 3 })

-- EDID fake for Sony Bravia @ Home (HDR + VRR)
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "3840x2160@120",
    position = "4000x0",
    scale    = 1.5,
    bitdepth = 10,
    cm       = "hdr",
    vrr      = 1,
})

-- EDID fake for Steam Deck w/ HDR (HDMI fallback)
hl.monitor({
    output   = "HDMI-A-2",
    mode     = "1280x800@90",
    position = "7840x0",
    scale    = 1,
})

-- Workspace -> monitor placement
hl.workspace_rule({ workspace = "1", monitor = "DP-1",     persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1",     persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1",     persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1",     persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-2",     persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-2" })
