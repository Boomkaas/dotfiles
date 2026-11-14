#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# ==============================================================================
# Connection notifications
# Watches Wi-Fi (NetworkManager, via `nmcli monitor`) and Bluetooth (BlueZ, via
# the PropertiesChanged signals of org.bluez.Device1.Connected) and shows a
# notification whenever a network or device connects or disconnects.
#
# Runs as a user service for the whole session (nixos/system/configuration.nix).
# Networks and devices that are already connected at startup are not announced.
# Each watcher is respawned if its monitor exits (e.g. NetworkManager restarts).
#
# Usage: connection_notify.sh
# ==============================================================================

notify() { # notify <app> <icon> <title> <body>
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "$1" -i "$2" -t 4000 "$3" "$4"
}

# Wi-Fi: nmcli prints "<device>: <state>" on every device state change.
watch_wifi() {
    declare -A ssid_of=()   # wifi device -> connection name it is up on
    local dev type state ssid old line

    # Seed with the networks that are already up, so they are not announced.
    while IFS=: read -r dev type state; do
        if [ "$type" = wifi ] && [ "$state" = connected ]; then
            ssid_of[$dev]=$(nmcli -g GENERAL.CONNECTION device show "$dev" 2>/dev/null)
        fi
    done < <(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null)

    stdbuf -oL nmcli monitor 2>/dev/null | while IFS= read -r line; do
        dev=${line%%: *}
        state=${line#*: }
        # Other monitor lines (connectivity, hostname, ...) do not match.
        case $state in connected|disconnected) ;; *) continue ;; esac
        [ "$(nmcli -g GENERAL.TYPE device show "$dev" 2>/dev/null)" = wifi ] || continue

        if [ "$state" = connected ]; then
            ssid=$(nmcli -g GENERAL.CONNECTION device show "$dev" 2>/dev/null)
            ssid_of[$dev]=$ssid
            notify Wi-Fi network-wireless-connected "Wi-Fi connected" "${ssid:-Network}"
        elif [[ -v ssid_of[$dev] ]]; then
            # Only announce drops of a network we saw come up; this keeps
            # "disconnected" from firing on resume or while the radio is off.
            old=${ssid_of[$dev]}
            unset "ssid_of[$dev]"
            notify Wi-Fi network-wireless-disconnected "Wi-Fi disconnected" "${old:+Was connected to $old}"
        fi
    done
}

# Bluetooth: a Connected flip arrives as PropertiesChanged on the device object.
# InterfacesAdded (device discovery) also carries 'Connected', so it is excluded.
watch_bluetooth() {
    local line path name title icon
    stdbuf -oL gdbus monitor --system --dest org.bluez 2>/dev/null | while IFS= read -r line; do
        [[ $line == *Properties.PropertiesChanged* && $line == *org.bluez.Device1* && $line == *"'Connected': <"* ]] || continue
        case $line in
            *"'Connected': <true>"*)  title="Bluetooth connected";    icon=bluetooth-active ;;
            *"'Connected': <false>"*) title="Bluetooth disconnected"; icon=bluetooth-disabled ;;
            *) continue ;;
        esac
        # The signal's object path is e.g. /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF.
        path=${line%%:*}
        name=$(busctl --system get-property org.bluez "$path" org.bluez.Device1 Alias 2>/dev/null \
            | sed -n 's/^s "\(.*\)"$/\1/p')
        notify Bluetooth "$icon" "$title" "${name:-Unknown device}"
    done
}

# Run a watcher again whenever its monitor exits.
respawn() {
    while true; do
        "$1"
        sleep 5
    done
}

respawn watch_wifi &
respawn watch_bluetooth &
wait
