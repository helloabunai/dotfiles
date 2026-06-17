-- ============================================================================
-- Global Hyprland config: general / decoration / input / misc / etc.
-- ============================================================================

hl.config({
    general = {
        gaps_in     = 1,
        gaps_out    = 2,
        border_size = 2,
        col = {
            active_border   = "rgba(435964aa)",
            inactive_border = "rgba(B3BCC1aa)",
        },
        resize_on_border = true,
    },

    decoration = {
        rounding = 5,
        -- Gruvbox Retro HyDE theme blur (hyprlang theme.conf isn't sourced under Lua)
        blur = {
            enabled           = true,
            size              = 4,
            passes            = 2,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
        },
    },

    input = {
        kb_layout      = "eu",
        follow_mouse   = 1,
        sensitivity    = 1,
        force_no_accel = true,
        accel_profile  = "flat",
    },

    misc = {
        force_default_wallpaper      = -1,
        disable_hyprland_logo        = true,
        focus_on_activate            = false,
        middle_click_paste           = false,
        render_unfocused_fps         = 141,
        always_follow_on_dnd         = true,
        -- Waybar starts at boot while HDMI-A-1 + ws 6 still exist (before
        -- remote_cleanup.sh disables them); with tracking on, child processes
        -- spawned via waybar on-click inherit that workspace tag and land on
        -- the now-disabled monitor (pavucontrol invisible, etc.). Disable.
        initial_workspace_tracking   = 0,
        screencopy_force_8b          = false,
    },

    ecosystem = {
        no_update_news = true,
    },

    render = {
        cm_enabled  = true,
        cm_auto_hdr = 1,
    },

    cursor = {
        no_hardware_cursors = 1, -- nvidia: keep HW cursors off
        -- Auto-hide cursor after N seconds of mouse inactivity. Native
        -- Hyprland mechanism so it doesn't generate synthetic motion events
        -- that hypridle would mistake for activity; cursor is therefore
        -- already hidden by the time the screensaver kicks in.
        inactive_timeout    = 5,
        -- Don't warp the cursor on focus/workspace/fullscreen changes.
        -- Side benefit: screensaver.sh's pre-spawn cursor capture would no
        -- longer pick up a synthetic warp jump.
        no_warps            = true,
    },

    debug = {
        suppress_errors = true,
        vfr             = true,
    },

    animations = {
        enabled = true,
    },
})
