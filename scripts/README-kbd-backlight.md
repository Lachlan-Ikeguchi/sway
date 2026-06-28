# Keyboard Backlight Control - Setup Instructions

## Overview

This setup adds keyboard backlight toggling when the laptop lid is closed, using Sway's native `bindswitch` events for efficient and reliable lid state detection.

## Required One-Time Setup (as root)

### 1. Create udev rule

The keyboard backlight device (`/sys/class/leds/platform::kbd_backlight/brightness`) is owned by root and requires special permissions to allow user access.

Run as root:
```bash
sudo tee /etc/udev/rules.d/99-kbd-backlight.rules > /dev/null << 'EOF'
ACTION=="add|change", SUBSYSTEM=="leds", KERNEL=="platform::kbd_backlight", MODE="0664", GROUP="video"
EOF
```

### 2. Add user to video group

```bash
sudo usermod -aG video lachlan
```

### 3. Reload udev rules

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 4. Logout and login again

The group membership change requires a new login session to take effect.

### 5. Verify permissions

After logging back in, verify you can write to the backlight file:
```bash
echo "2" > /sys/class/leds/platform::kbd_backlight/brightness
```

If this fails, you may need to check:
- You're in the `video` group: `groups`
- The udev rule was applied: `ls -la /sys/class/leds/platform::kbd_backlight/brightness`
- The device group is correct: `stat /sys/class/leds/platform::kbd_backlight/brightness`

## Alternative: Passwordless sudo

If udev rules don't work, you can set up passwordless sudo for the specific command:

```bash
sudo tee /etc/sudoers.d/kbd-backlight > /dev/null << 'EOF'
# Allow lachlan to control keyboard backlight without password
lachlan ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/leds/platform::kbd_backlight/brightness
EOF
```

## Architecture

The system uses:
- **Sway bindswitch events**: Direct lid close/open detection (most efficient)
- **swayidle events**: Sleep/wake detection (for suspend/resume scenarios)
- **Unified lid-switch.sh**: Single script handling both display and keyboard backlight

## Files Modified

- `~/.config/sway/scripts/lid-switch.sh` - Enhanced with keyboard backlight control
- `~/.config/sway/config` - Added bindswitch commands, updated swayidle config
- `~/.config/sway/scripts/lid-monitor.sh` - Deprecated (polling script no longer needed)

## Usage

After setup, the system will:
- Turn off keyboard backlight when lid is closed
- Restore keyboard backlight to previous state when lid is opened
- Continue to handle display toggling as before
- Work with both direct lid events and system sleep/wake events