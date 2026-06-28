#!/bin/bash

# --- Configuration ---
KBD_BACKLIGHT_PATH="/sys/class/leds/platform::kbd_backlight/brightness"
KBD_BACKLIGHT_STATE_FILE="/tmp/kbd_backlight_state_$(whoami)"

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

# --- Keyboard backlight functions ---
get_kbd_backlight() {
    [ -f "$KBD_BACKLIGHT_PATH" ] && cat "$KBD_BACKLIGHT_PATH" || echo "0"
}

set_kbd_backlight() {
    local value=$1
    # After udev rule setup, this should work without sudo
    if [ -f "$KBD_BACKLIGHT_PATH" ]; then
        if [ -w "$KBD_BACKLIGHT_PATH" ]; then
            echo "$value" > "$KBD_BACKLIGHT_PATH"
        else
            # Fallback with sudo if udev rules not set up
            echo "$value" | sudo tee "$KBD_BACKLIGHT_PATH" >/dev/null
        fi
    fi
}

save_kbd_backlight_state() {
    local current=$(get_kbd_backlight)
    echo "$current" > "$KBD_BACKLIGHT_STATE_FILE"
}

restore_kbd_backlight_state() {
    if [ -f "$KBD_BACKLIGHT_STATE_FILE" ]; then
        local saved=$(cat "$KBD_BACKLIGHT_STATE_FILE")
        set_kbd_backlight "$saved"
        rm -f "$KBD_BACKLIGHT_STATE_FILE"
    fi
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

disable_internal_display() {
    local INTERNAL=$(get_internal_output)
    if [ -n "$INTERNAL" ]; then
        swaymsg output "$INTERNAL" disable
        # Enable all other outputs
        swaymsg -t get_outputs | jq -r --arg internal "$INTERNAL" '.[] | select(.name != $internal) | .name' | \
            while read -r output; do
                swaymsg output "$output" enable
            done
    fi
}

enable_internal_display() {
    local INTERNAL=$(get_internal_output)
    [ -n "$INTERNAL" ] && swaymsg output "$INTERNAL" enable
}

# --- Main logic ---
handle_lid_close() {
    # Save and turn off keyboard backlight
    save_kbd_backlight_state
    set_kbd_backlight 0
    
    # Disable internal display
    disable_internal_display
}

handle_lid_open() {
    # Restore keyboard backlight
    restore_kbd_backlight_state
    
    # Enable internal display
    enable_internal_display
}

# Accept command line argument or detect state
if [ $# -ge 1 ]; then
    case "$1" in
        close|off)
            handle_lid_close
            ;;
        open|on)
            handle_lid_open
            ;;
        *)
            echo "Usage: $0 {close|open}"
            exit 1
            ;;
    esac
else
    # Legacy behavior: auto-detect lid state (for backward compatibility)
    LID_STATE=$(get_lid_state)
    if [ "$LID_STATE" = "closed" ]; then
        handle_lid_close
    else
        handle_lid_open
    fi
fi
