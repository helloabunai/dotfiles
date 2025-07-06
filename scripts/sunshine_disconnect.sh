## use already added EDID monitor for sunshine output
## disable it upon sunshine session end event

hyprctl keyword monitor HDMI-A-1,disable
echo "Removed virtual EDID monitor from compositor..."
