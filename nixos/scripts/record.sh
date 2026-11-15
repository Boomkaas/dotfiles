#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# This script is used to record the screen and audio using wl-screenrec and PipeWire
# It sets up a virtual audio sink to combine microphone and system audio, and manages the recording process
# 3 modes are available: Only Sound, Micro and Sound, No Sound

# Auto-detect VA-API driver on NixOS / Linux if not already in standard path
if [ -z "${LIBVA_DRIVERS_PATH:-}" ]; then
    if [ -f "/run/opengl-driver/lib/dri/iHD_drv_video.so" ]; then
        export LIBVA_DRIVERS_PATH="/run/opengl-driver/lib/dri"
        export LIBVA_DRIVER_NAME="iHD"
    else
        ihd_path=$(ls -d /nix/store/*-intel-media-driver-*/lib/dri 2>/dev/null | head -n 1)
        if [ -n "$ihd_path" ]; then
            export LIBVA_DRIVERS_PATH="$ihd_path"
            export LIBVA_DRIVER_NAME="iHD"
        fi
    fi
fi

# Defaults
SCREENREC_SAVE_DIR=${SCREENREC_SAVE_DIR:-"$HOME/Videos"}
REC_COMMAND=${REC_COMMAND:-"wl-screenrec"}
REC_OPTS=${REC_OPTS:-"--codec avc --encode-pixfmt nv12 --low-power=off"}

PID_FILE="/tmp/recording_pid"
TIME_FILE="/tmp/recording_time"
AUDIO_MODULES_FILE="/tmp/recording_audio_modules"
KEEPALIVE_PID_FILE="/tmp/recording_keepalive_pid"
COMBINED_SINK_NAME="rec_combined_sink"
LOCKED_SAMPLE_RATE="${SCREENREC_LOCK_RATE:-48000}"
LOCKED_QUANTUM="${SCREENREC_LOCK_QUANTUM:-1024}"

# Print debug directly to terminal
debug_log() {
    if [ "${SCREENREC_DEBUG:-0}" = "1" ]; then
        echo "[$(date +%H:%M:%S) DEBUG] $*"
    fi
}

# Check if recording is currently active
is_recording() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Pick one line of stdin with fzf. From a niri bind there is no terminal, so the
# picker opens in a floating kitty (app-id tui-overlay, see config/niri/config.kdl).
pick() {
    local prompt="$1"
    if [ -t 0 ] && [ -t 1 ]; then
        fzf --prompt="$prompt > " --reverse --height=40% --border=rounded
        return
    fi
    local in out
    in=$(mktemp) && out=$(mktemp)
    cat > "$in"
    kitty --class tui-overlay --title "$prompt" \
        bash -c 'fzf --prompt="$1 > " --reverse --border=rounded < "$2" > "$3"' _ "$prompt" "$in" "$out"
    cat "$out"
    rm -f "$in" "$out"
}

# Dependency checks (only performed when starting a recording)
check_dependencies() {
    local missing=()
    if ! command -v "$REC_COMMAND" &> /dev/null; then
        missing+=("$REC_COMMAND")
    fi
    if ! command -v pactl &> /dev/null; then
        missing+=("pactl")
    fi
    if [ ${#missing[@]} -gt 0 ]; then
        notify-send -u critical "Recording System" "Missing dependencies (${missing[*]})!" -i dialog-error
        return 1
    fi
    return 0
}

# Setup virtual null-sink and loopbacks for mic + system audio
setup_virtual_audio() {
    local mic_device="$1"
    local real_sink="$2"
    local system_monitor="${real_sink}.monitor"
    
    debug_log "Init virtual audio: mic=$mic_device | sink=$real_sink"
    if [ -z "$real_sink" ]; then return 1; fi

    rm -f "$AUDIO_MODULES_FILE"

    # 1. Create null-sink
    local null_sink_module_id
    null_sink_module_id=$(pactl load-module module-null-sink \
        sink_name="$COMBINED_SINK_NAME" \
        sink_properties=device.description="RecordingCombinedAudio" 2>/dev/null)
    
    if [ -z "$null_sink_module_id" ]; then return 1; fi
    echo "$null_sink_module_id" >> "$AUDIO_MODULES_FILE"

    # Force default sink back to real sink to prevent feedback loops
    pactl set-default-sink "$real_sink" 2>/dev/null

    # 2. Loopback mic to null-sink
    local loopback_mic_id
    loopback_mic_id=$(pactl load-module module-loopback \
        source="$mic_device" \
        sink="$COMBINED_SINK_NAME" \
        latency_msec=1 2>/dev/null)
    
    if [ -z "$loopback_mic_id" ]; then
        teardown_virtual_audio
        return 1
    fi
    echo "$loopback_mic_id" >> "$AUDIO_MODULES_FILE"

    # Prevent recursive loopback
    if [ "$system_monitor" = "${COMBINED_SINK_NAME}.monitor" ]; then
        teardown_virtual_audio
        return 1
    fi

    # 3. Loopback system audio to null-sink
    local loopback_sys_id
    loopback_sys_id=$(pactl load-module module-loopback \
        source="$system_monitor" \
        sink="$COMBINED_SINK_NAME" \
        latency_msec=1 2>/dev/null)

    if [ -z "$loopback_sys_id" ]; then
        teardown_virtual_audio
        return 1
    fi
    echo "$loopback_sys_id" >> "$AUDIO_MODULES_FILE"

    return 0
}

# Remove virtual audio modules
teardown_virtual_audio() {
    if [ -f "$AUDIO_MODULES_FILE" ]; then
        tac "$AUDIO_MODULES_FILE" | while read -r module_id; do
            [ -n "$module_id" ] && pactl unload-module "$module_id" 2>/dev/null
        done
        rm -f "$AUDIO_MODULES_FILE"
        debug_log "Virtual audio modules unloaded"
    fi
}

# Lock PipeWire rate/quantum to prevent renegotiation crashes during stream pause
lock_pipewire_rate() {
    if ! command -v pw-metadata &> /dev/null; then return 1; fi
    pw-metadata -n settings 0 clock.force-rate "$LOCKED_SAMPLE_RATE" 2>/dev/null
    pw-metadata -n settings 0 clock.force-quantum "$LOCKED_QUANTUM" 2>/dev/null
    debug_log "Locked rate=$LOCKED_SAMPLE_RATE, quantum=$LOCKED_QUANTUM"
}

unlock_pipewire_rate() {
    if command -v pw-metadata &> /dev/null; then
        pw-metadata -n settings 0 clock.force-rate 0 2>/dev/null
        pw-metadata -n settings 0 clock.force-quantum 0 2>/dev/null
        debug_log "Unlocked PipeWire rate and quantum"
    fi
}

# Prevent default sink from auto-suspending by feeding it silent data
start_keepalive_silence() {
    local real_sink="$1"
    if [ -z "$real_sink" ] || ! command -v pacat &> /dev/null; then return 1; fi

    ( pacat --device="$real_sink" --raw --rate=48000 --channels=2 --format=s16le < /dev/zero & echo $! > "$KEEPALIVE_PID_FILE" ) 2>/dev/null
    sleep 0.05
    debug_log "Keepalive started on $real_sink"
}

stop_keepalive_silence() {
    if [ -f "$KEEPALIVE_PID_FILE" ]; then
        local kpid
        kpid=$(cat "$KEEPALIVE_PID_FILE" 2>/dev/null)
        [ -n "$kpid" ] && kill "$kpid" 2>/dev/null
        rm -f "$KEEPALIVE_PID_FILE"
        debug_log "Keepalive stopped"
    fi
}

stop_recording() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ]; then
            kill -SIGINT "$pid" 2>/dev/null
            while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
        fi
        
        rm -f "$PID_FILE" "$TIME_FILE"
        teardown_virtual_audio
        stop_keepalive_silence
        unlock_pipewire_rate
        
        notify-send -u normal "Recording System" "Saved Video" -i video-display
        debug_log "Recording stopped and saved"
    fi
}

start_recording() {
    if ! check_dependencies; then
        exit 1
    fi

    mkdir -p "$SCREENREC_SAVE_DIR"

    options="󰑊 Only Sound\n󰍬 Micro and Sound\n󰔊 No Sound"
    chosen=$(echo -e "$options" | pick "Record mode")
    if [ -z "$chosen" ]; then exit 0; fi

    FILENAME="recording_$(date +%Y%m%d_%H%M%S).mp4"
    FILEPATH="$SCREENREC_SAVE_DIR/$FILENAME"
    
    # Get actual default sink BEFORE creating virtual ones
    REAL_SINK=$(pactl get-default-sink 2>/dev/null)
    if [ -z "$REAL_SINK" ]; then
        notify-send -u critical "Recording System" "Default sink not found!" -i dialog-error
        exit 1
    fi

    debug_log "Starting record mode: $chosen | Real sink: $REAL_SINK"

    trap 'teardown_virtual_audio; stop_keepalive_silence; unlock_pipewire_rate' EXIT INT TERM

    case "$chosen" in
        *"Only Sound")
            lock_pipewire_rate
            start_keepalive_silence "$REAL_SINK"
            $REC_COMMAND $REC_OPTS --audio --audio-device "${REAL_SINK}.monitor" -f "$FILEPATH" &
            MSG="Recording: System Audio"
            ;;
        *"Micro and Sound")
            # Filter for physical mics only
            AUDIO_DEVICE=$(pactl list short sources | awk '{print $2}' | grep -viE '\.monitor$' | pick "Microphone")
            if [ -z "$AUDIO_DEVICE" ]; then exit 0; fi

            lock_pipewire_rate
            start_keepalive_silence "$REAL_SINK"

            if ! setup_virtual_audio "$AUDIO_DEVICE" "$REAL_SINK"; then
                stop_keepalive_silence
                unlock_pipewire_rate
                exit 1
            fi

            $REC_COMMAND $REC_OPTS --audio --audio-device "${COMBINED_SINK_NAME}.monitor" -f "$FILEPATH" &
            MSG="Recording: Mic + System Audio"
            ;;
        *"No Sound")
            $REC_COMMAND $REC_OPTS -f "$FILEPATH" &
            MSG="Recording: No Sound"
            ;;
    esac

    echo $! > "$PID_FILE"
    notify-send "Recording System" "$MSG" -i video-display -t 1000

    # Timer loop
    SEC=0
    while [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; do
        MIN=$((SEC / 60))
        S=$((SEC % 60))
        printf "%02d:%02d" $MIN $S > "$TIME_FILE"
        sleep 1
        SEC=$((SEC + 1))
    done

    # Cleanup if wl-screenrec exits on its own
    rm -f "$PID_FILE" "$TIME_FILE"
    teardown_virtual_audio
    stop_keepalive_silence
    unlock_pipewire_rate
}

# Main routing based on CLI flags
case "$1" in
    --stop)
        if is_recording; then
            stop_recording
        fi
        ;;
    --start)
        if ! is_recording; then
            start_recording
        fi
        ;;
    --toggle|"")
        if is_recording; then
            stop_recording
        else
            start_recording
        fi
        ;;
    *)
        echo "Usage: $0 {--start|--stop|--toggle}"
        exit 1
        ;;
esac