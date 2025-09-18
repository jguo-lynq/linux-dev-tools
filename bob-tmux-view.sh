#!/bin/bash

num_devices=$#
device_indices=("$@")

# 1) Create the new window for the first device
tmux new-window -n "BoBs" "minicom -D /dev/rtHST${device_indices[0]}-0"

# Split horizontally for columns (66%, then 50% of what's left)
tmux split-window -h -l 66% "minicom -D /dev/rtDBG${device_indices[0]}-1"
tmux split-window -h -l 50% "minicom -D /dev/rtDBG${device_indices[0]}-0"

for i in $(seq 1 $((num_devices - 1))); do
    # Calculate the fraction for vertical split
    remaining=$((num_devices - i + 1))  # e.g., if i=1, with 3 devices total => remaining=3
    percent=$((100 / remaining))        # e.g. 100/3 => 33, 100/2 => 50, etc.

    tmux select-pane -t 0
    tmux split-window -v -f -l "${percent}%" "minicom -D /dev/rtHST${device_indices[$i]}-0"

    # Now in that newly-split pane, do your 3 columns again
    # But you have to select that new pane we just created.
    # By default, tmux focuses it, but you might need to confirm with `tmux select-pane -t <pane_id>`.
    tmux split-window -h -l 66% "minicom -D /dev/rtDBG${device_indices[$i]}-1"
    tmux split-window -h -l 50% "minicom -D /dev/rtDBG${device_indices[$i]}-0"
done

