#!/bin/bash

# Helper function to launch a horizontal split with history tracking
run_with_history() {
    local percent="$1"
    local cmd="$2"
    tmux split-window -h -l "$percent" \
        "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"$cmd\"; $cmd')"
}

# Helper function to launch a vertical split with history tracking
run_vert_with_history() {
    local percent="$1"
    local cmd="$2"
    tmux split-window -v -f -l "$percent%" \
        "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"$cmd\"; $cmd')"
}

num_devices=$#
device_indices=("$@")

# --- Start tmux session for first device ---

# Create a new window for the first host console
tmux new-window -n "BoBs" \
    "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"minicom -D /dev/rtHST${device_indices[0]}-0\"; minicom -D /dev/rtHST${device_indices[0]}-0')"

# Add DBG and SDK panes horizontally
run_with_history 75% "minicom -b 921600 -D /dev/rtDBG${device_indices[0]}-1"
run_with_history 66% "minicom -D /dev/rtDBG${device_indices[0]}-0"
run_with_history 50% "cd \"$HOME/dev/raven-sdk\" && ./bin/configure.debug /dev/rtHST${device_indices[0]}-1"

# --- Add additional devices vertically ---
for i in $(seq 1 $((num_devices - 1))); do
    remaining=$((num_devices - i + 1))
    percent=$((100 / remaining))

    tmux select-pane -t 0
    run_vert_with_history "$percent" "minicom -D /dev/rtHST${device_indices[$i]}-0"

    run_with_history 75% "minicom -b 921600 -D /dev/rtDBG${device_indices[$i]}-1"
    run_with_history 66% "minicom -D /dev/rtDBG${device_indices[$i]}-0"
    run_with_history 50% "cd \"$HOME/dev/raven-sdk\" && ./bin/configure.debug /dev/rtHST${device_indices[$i]}-1"
done

