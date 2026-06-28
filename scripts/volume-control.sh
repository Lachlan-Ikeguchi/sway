#!/bin/bash

WOBPIPE=/tmp/wobpipe

# Function to ensure wob reader is running
ensure_wob() {
    # Create pipe if it doesn't exist
    if [ ! -p "$WOBPIPE" ]; then
        rm -f "$WOBPIPE"
        mkfifo "$WOBPIPE"
    fi
    
    # Start wob reader in a loop so it restarts if wob dies
    if ! pgrep -f "tail -f $WOBPIPE" > /dev/null 2>&1; then
        (while true; do tail -f "$WOBPIPE" | wob; sleep 1; done) &
    fi
}

# Function to get current volume percentage
get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}' | sed 's/\[MUTED\]//g'
}

# Function to send volume to wob
send_to_wob() {
    local volume=$1
    echo "$volume" > "$WOBPIPE"
}

# Handle command line arguments
case "$1" in
    start)
        ensure_wob
        ;;
    up)
        ensure_wob
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        volume=$(printf "%.0f" $(echo "scale=4; $(get_volume) * 100" | bc -l))
        send_to_wob "$volume"
        ;;
    down)
        ensure_wob
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        volume=$(printf "%.0f" $(echo "scale=4; $(get_volume) * 100" | bc -l))
        send_to_wob "$volume"
        ;;
    toggle)
        ensure_wob
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        # Optionally show mute status
        if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "\[MUTED\]"; then
            send_to_wob "MUTED"
        else
            volume=$(printf "%.0f" $(echo "scale=4; $(get_volume) * 100" | bc -l))
            send_to_wob "$volume"
        fi
        ;;
    *)
        echo "Usage: $0 {start|up|down|toggle}"
        exit 1
        ;;
esac
