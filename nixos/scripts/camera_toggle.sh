#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# ==============================================================================
# Webcam Kill Switch
# Blocks/unblocks the built-in UVC webcam by toggling its USB `authorized` flag.
# A deauthorized device stays enumerated but no driver can bind to it, so no
# app can open it. Write access is granted to the `video` group by a udev rule
# in nixos/modules/core/services.nix.
# ==============================================================================

CAM_VENDOR="13d3"
CAM_PRODUCT="5a11"

cam=""
for dev in /sys/bus/usb/devices/*; do
    [[ -f "$dev/idVendor" && -f "$dev/idProduct" ]] || continue
    if [[ "$(<"$dev/idVendor")" == "$CAM_VENDOR" && "$(<"$dev/idProduct")" == "$CAM_PRODUCT" ]]; then
        cam="$dev"
        break
    fi
done

if [[ -z "$cam" ]]; then
    notify-send -i camera-web "Camera" "Webcam ${CAM_VENDOR}:${CAM_PRODUCT} not found"
    exit 1
fi

if [[ ! -w "$cam/authorized" ]]; then
    notify-send -i camera-web "Camera" "No write access to $cam/authorized (rebuild NixOS to apply the udev rule)"
    exit 1
fi

if [[ "$(<"$cam/authorized")" == "1" ]]; then
    echo 0 > "$cam/authorized" && notify-send -i camera-disabled-symbolic "Camera" "Blocked"
else
    echo 1 > "$cam/authorized" && notify-send -i camera-web "Camera" "Unblocked"
fi
