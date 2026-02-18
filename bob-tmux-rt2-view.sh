#!/bin/bash

use_unkindness=false
use_debug=false

# Parse options
while getopts ":ud" opt; do
  case $opt in
    u) use_unkindness=true ;;
    d) use_debug=true ;;
    \?) echo "Usage: $0 [-u] [-d] device_indices..."; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

num_devices=$#
device_indices=("$@")

# Create a new window for the first host console
tmux new-window -n "BoBs" \
    "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"minicom -b 921600 -D /dev/rtDBG${device_indices[0]}-log\"; minicom -b 921600 -D /dev/rtDBG${device_indices[0]}-log')"

# Loop through the rest of the devices and attach debug for 9151
for i in $(seq 1 $((num_devices - 1))); do
    tmux split-window -h -c "#{pane_current_path}" \
    "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"minicom -b 921600 -D /dev/rtDBG${device_indices[$i]}-log\"; minicom -b 921600 -D /dev/rtDBG${device_indices[$i]}-log')"
done


tmux select-layout even-horizontal
tmux select-pane -t 1

#cd to unkindness test
if $use_unkindness; then
    for ((i=0; i<num_devices; i++)); do
    
        tmux split-window -c "#{pane_current_path}" \
        "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"cd $HOME/dev/unkindess-test && ./bin/devtest --sdk_port /dev/rtDBG${device_indices[$i]}-sdk --formation_cycles 100 --formation_cycle_time 15 --formation_time 15\"; cd $HOME/dev/unkindess-test')"
    
        tmux select-pane -R
    done
fi

#attach to configure app for each device
if $use_debug; then
    for ((i=0; i<num_devices; i++)); do
    
        tmux split-window -c "#{pane_current_path}" \
        "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"cd $HOME/dev/raven-sdk && ./bin/configure /dev/rtDBG${device_indices[$i]}-sdk\"; cd $HOME/dev/raven-sdk && ./bin/configure /dev/rtDBG${device_indices[$i]}-sdk')"
    
        tmux select-pane -R
    done
else
    for ((i=0; i<num_devices; i++)); do
    
        tmux split-window -c "#{pane_current_path}" \
        "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"cd $HOME/dev/raven-sdk && ./bin/configure /dev/rtHST${device_indices[$i]}-sdk\"; cd $HOME/dev/raven-sdk && ./bin/configure /dev/rtHST${device_indices[$i]}-sdk')"
    
        tmux select-pane -R
    done
fi

win_num=$(tmux display-message -p '#I')
echo "Current window: $win_num"

~/bin/scripts/tmux-move-to-front.sh $win_num
