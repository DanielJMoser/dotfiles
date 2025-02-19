#!/bin/bash

# Monitor Brightness Adjustment Script for Hyprland
# Usage: ./brightness.sh <brightness level (0-100)> [monitor number]

# Check for dependencies
if ! command -v ddcutil &> /dev/null; then
    echo "ddcutil is not installed. Please install it with 'sudo pacman -S ddcutil'."
    exit 1
fi

# Check for root or appropriate permissions
if ! [ -w /dev/i2c-* ]; then
    echo "You need root or 'i2c' group permissions to adjust brightness."
    exit 1
fi

# Validate input
if [[ -z "$1" || "$1" -lt 0 || "$1" -gt 100 ]]; then
    echo "Usage: $0 <brightness level (0-100)> [monitor number]"
    exit 1
fi

BRIGHTNESS=$1
MONITOR=${2:-1}  # Default to monitor 1 if not specified

# Adjust brightness
ddcutil --display "$MONITOR" setvcp 10 "$BRIGHTNESS"
if [ $? -eq 0 ]; then
    echo "Brightness set to $BRIGHTNESS% on monitor $MONITOR."
else
    echo "Failed to adjust brightness. Check your monitor's DDC/CI settings."
    exit 1
fi

