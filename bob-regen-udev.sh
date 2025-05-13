#!/bin/bash

set -euo pipefail

RULES_FILE="/etc/udev/rules.d/60-usb-serial.rules"

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <device-idx> [--apply|--replace]"
    exit 1
fi

device_idx=$1
mode=${2:-""}

# Sanity check for available devices
usb_count=$(ls /dev/serial/by-id/usb-ZEPHYR_LNQ3195_*if00* 2>/dev/null | wc -l)
uart_count=$(ls /dev/serial/by-id/usb-Silicon_Labs_CP2105_Dual_USB_to_UART_Bridge_Controller_*if00* 2>/dev/null | wc -l)

if [[ ${usb_count} != "1" || ${uart_count} != "1" ]]; then
    echo "Please ensure only ONE radio is plugged in and turned on."
    echo "Found: ${usb_count} Zephyr + ${uart_count} CP2105 devices."
    exit 1
fi

# Resolve ID_PATHs — abort if any fail
host0_path=$(udevadm info /dev/serial/by-id/usb-ZEPHYR_LNQ3195_*if00* | grep "ID_PATH=" | cut -d= -f2)
host1_path=$(udevadm info /dev/serial/by-id/usb-ZEPHYR_LNQ3195_*if03* | grep "ID_PATH=" | cut -d= -f2)
debug0_path=$(udevadm info /dev/serial/by-id/usb-Silicon_Labs_CP2105_Dual_USB_to_UART_Bridge_Controller_*if00* | grep "ID_PATH=" | cut -d= -f2)
debug1_path=$(udevadm info /dev/serial/by-id/usb-Silicon_Labs_CP2105_Dual_USB_to_UART_Bridge_Controller_*if01* | grep "ID_PATH=" | cut -d= -f2)

if [[ -z "$host0_path" || -z "$host1_path" || -z "$debug0_path" || -z "$debug1_path" ]]; then
    echo "Error: Failed to resolve one or more ID_PATH values."
    exit 1
fi

# Prepare the new rule block
rule_lines=$(cat <<EOF
SUBSYSTEM=="tty", ENV{ID_PATH}=="${host0_path}", SYMLINK+="rtHST${device_idx}-0"
SUBSYSTEM=="tty", ENV{ID_PATH}=="${host1_path}", SYMLINK+="rtHST${device_idx}-1"
SUBSYSTEM=="tty", ENV{ID_PATH}=="${debug0_path}", SYMLINK+="rtDBG${device_idx}-0"
SUBSYSTEM=="tty", ENV{ID_PATH}=="${debug1_path}", SYMLINK+="rtDBG${device_idx}-1"
EOF
)

# Show preview always
echo "Generated udev rules (preview only):"
echo "$rule_lines"
echo

# Only apply if requested
if [[ "$mode" == "--apply" ]]; then
    existing_count=$(grep -c "rtHST${device_idx}-\|rtDBG${device_idx}-" "$RULES_FILE" 2>/dev/null || true)

    if [[ "$existing_count" -gt 0 ]]; then
        echo "Rules for device index $device_idx already exist in $RULES_FILE."
        echo "Use '--replace' to overwrite them."
        exit 1
    fi

    echo "Appending new rules to ${RULES_FILE}..."
    echo "$rule_lines" | sudo tee -a "$RULES_FILE" > /dev/null

elif [[ "$mode" == "--replace" ]]; then
    echo "Replacing rules for device index $device_idx in ${RULES_FILE}..."
    sudo sed -i "/rtHST${device_idx}-\|rtDBG${device_idx}-/d" "$RULES_FILE"
    echo "$rule_lines" | sudo tee -a "$RULES_FILE" > /dev/null
else
    echo "To apply these rules, run:"
    echo "  $0 $device_idx --apply"
    echo "To overwrite existing rules for this device ID:"
    echo "  $0 $device_idx --replace"
    exit 0
fi

# Apply and reload rules
echo "Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "Resulting symlinks:"
ls -l /dev/rtDBG${device_idx}-* /dev/rtHST${device_idx}-* 2>/dev/null || echo "(Not visible yet — try replugging device)"

