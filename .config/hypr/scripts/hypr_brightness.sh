#!/usr/bin/env sh

# Accept an arg '+' or '-'
direction=$1
case "$direction" in
    +|-) ;;
    *) echo "Usage: $0 + | -" >&2; exit 1 ;;
esac

# Get monitor info
monitor_data=$(hyprctl monitors -j)
focused_name=$(echo "$monitor_data" | jq -r '.[] | select(.focused == true) | .name')

case "$focused_name" in
    eDP-*)
        # Internal display is focused -> use the kernel backlight
        brightnessctl --quiet set "8%$direction"
        ;;
    *)
        # External display is focused -> use ddcutil
        # But *which* external display?
        focused_id=$(echo "$monitor_data" | jq -r '.[] | select(.focused == true) | .id')
        ddcutil --display="$focused_id" setvcp 10 "$direction" 8
        ;;
esac
