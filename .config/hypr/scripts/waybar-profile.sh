#!/bin/sh
# Starts Waybar with one of two profiles, and never leaves more than one running.
#
#   waybar-profile.sh [toggle]    stop Waybar, start the other profile, save the choice
#   waybar-profile.sh --restore   start the saved profile (used at login)
#
# Profiles: archipelago (~/.config/waybar/archipelago/) and classic (the old
# ~/.config/waybar/config.jsonc + style.css). The choice is saved in
# $XDG_STATE_HOME/waybar/profile; a missing, empty or unknown value means archipelago.
# Waybar's warnings and errors go to waybar.log next to it.

waybar_dir="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
state_file="$state_dir/profile"
uid=$(id -u)

saved_profile() {
    case "$(cat "$state_file" 2>/dev/null)" in
        classic) echo classic ;;
        *) echo archipelago ;;
    esac
}

case "${1:-toggle}" in
    toggle)
        if [ "$(saved_profile)" = archipelago ]; then profile=classic; else profile=archipelago; fi ;;
    --restore)
        profile=$(saved_profile) ;;
    *)
        echo "usage: ${0##*/} [toggle|--restore]" >&2
        exit 2 ;;
esac

case "$profile" in
    archipelago) config="$waybar_dir/archipelago/config.jsonc" style="$waybar_dir/archipelago/style.css" ;;
    classic) config="$waybar_dir/config.jsonc" style="$waybar_dir/style.css" ;;
esac

mkdir -p "$state_dir"

# One switch at a time, so a double key press can't start two bars.
exec 9>"$state_dir/lock"
flock -w 10 9 || exit 1

pkill -x -U "$uid" waybar
tries=0
while pgrep -x -U "$uid" waybar >/dev/null; do
    tries=$((tries + 1))
    [ "$tries" -eq 50 ] && pkill -KILL -x -U "$uid" waybar
    sleep 0.1
done

printf '%s\n' "$profile" >"$state_file"

waybar -l warning -c "$config" -s "$style" >"$state_dir/waybar.log" 2>&1 9>&- &

# Keep the lock until the child has become "waybar", so a queued switch can see and stop it.
while [ "$(cat "/proc/$!/comm" 2>/dev/null)" != waybar ] && kill -0 "$!" 2>/dev/null; do
    sleep 0.05
done
