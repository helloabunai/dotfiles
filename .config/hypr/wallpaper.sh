#!/bin/bash
main() {
    local selected_wallpaper="$1"
    swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
    wal -i "$selected_wallpaper" -n --cols16
    swaync-client --reload-css
    cat ~/.cache/wal/colors-kitty.conf > ~/.config/kitty/current-theme.conf
    pywalfox update
}

