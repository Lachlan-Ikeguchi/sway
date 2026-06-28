#!/bin/bash

# Autostart applications for Sway
# Add your applications here, one per line

# Easy Effects (PulseAudio effects)
flatpak run com.github.wwmm.easyeffects &
flatpak run org.signal.Signal &
flatpak run com.dropbox.Client &
flatpak run com.valvesoftware.Steam &
flatpak run com.discordapp.Discord &

# Add more applications below as needed:
# firefox &
# discord &
# spotify &
# etc.
