#!/bin/bash

# Get lid state from ACPI
get_lid_state() {
    grep -q "closed" /proc/acpi/button/lid/*/state 2>/dev/null && echo "closed" || echo "open"
}

# Initial run
~/.config/sway/scripts/lid-switch.sh

# Poll for changes (every 2 seconds)
LAST_STATE=$(get_lid_state)
while true; do
    sleep 2
    CURRENT_STATE=$(get_lid_state)
    if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
        ~/.config/sway/scripts/lid-switch.sh
        LAST_STATE="$CURRENT_STATE"
    fi
done
