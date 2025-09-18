#!/bin/bash
# Usage: tmux-move-to-front.sh <window-number> [session-name]
# Assumes tmux base-index is 1.
# Example: if your current window order is: 1 2 3 4 and you pass "4",
# the final order will be: 4 1 2 3, with window 4 also selected.

if [ -z "$1" ]; then
    echo "Usage: $0 <window-number> [session-name]"
    exit 1
fi

session="${2:-$(tmux display-message -p '#S')}"
target="$1"

# Get the unique window ID for the target window.
target_id=$(tmux list-windows -t "$session" -F "#{window_index}:#{window_id}" \
            | grep "^$target:" | cut -d: -f2)

if [ -z "$target_id" ]; then
    echo "Window $target not found in session $session"
    exit 1
fi

# Loop until the target window's index is 1.
while true; do
    current_index=$(tmux display-message -p -t "$session:$target_id" '#I')
    if [ "$current_index" = "1" ]; then
        break
    fi
    prev_index=$(( current_index - 1 ))
    tmux swap-window -s "$session:$target_id" -t "$session:$prev_index" 2>/dev/null
done

# Select window 1 to make it active.
tmux select-window -t "$session:1"

echo "Moved window $target to the front and activated window 1."

