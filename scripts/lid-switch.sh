#!/bin/bash

# --- Detect lid state ---
get_lid_state() {
    # Method 1: Check ACPI (most reliable)
    if [ -d "/proc/acpi/button/lid" ]; then
        grep -q "closed" /proc/acpi/button/lid/*/state 2>/dev/null && echo "closed" && return
    fi

    # Method 2: Check UPower
    if command -v upower &>/dev/null; then
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null | \
            grep -q "lid-is-closed: yes" && echo "closed" && return
    fi

    # Method 3: Check sysfs (some laptops)
    if [ -f "/sys/class/dmi/id/chassis_vendor" ]; then
        cat /sys/class/dmi/id/chassis_vendor 2>/dev/null | grep -qi "dell\|lenovo\|hp\|acer" && \
            [ -f "/sys/class/leds/platform::kbd_backlight/brightness" ] && \
            echo "open" && return
    fi

    # Default to open if undetected
    echo "open"
}

# --- Get internal output ---
get_internal_output() {
    swaymsg -t get_outputs | jq -r '
        .[]
        | select(
            (.name | test("eDP|LVDS|DSI")) or
            ((.description // "") | ascii_downcase | test("laptop|built.in|internal"))
          )
        | .name
    ' | head -1
}

# --- Main logic ---
LID_STATE=$(get_lid_state)
INTERNAL=$(get_internal_output)

if [ "$LID_STATE" = "closed" ] && [ -n "$INTERNAL" ]; then
    swaymsg output "$INTERNAL" disable
    swaymsg -t get_outputs | jq -r --arg internal "$INTERNAL" '.[] | select(.name != $internal) | .name' | \
        while read -r output; do
            swaymsg output "$output" enable
        done
else
    if [ -n "$INTERNAL" ]; then
        swaymsg output "$INTERNAL" enable
    fi
fi
