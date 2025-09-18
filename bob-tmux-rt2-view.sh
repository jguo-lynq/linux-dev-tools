#!/bin/bash

use_unkindness=false

# Parse options
while getopts ":u" opt; do
  case $opt in
    u) use_unkindness=true ;;
    \?) echo "Usage: $0 [-u] device_indices..."; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

num_devices=$#
device_indices=("$@")

# Create a new window for the first host console
tmux new-window -n "BoBs" \
    "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"minicom -b 921600 -D /dev/rtDBG${device_indices[0]}-1\"; minicom -b 921600 -D /dev/rtDBG${device_indices[0]}-1')"

# Loop through the rest of the devices and attach debug for 9151
for i in $(seq 1 $((num_devices - 1))); do
    tmux split-window -h -c "#{pane_current_path}" \
    "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"minicom -b 921600 -D /dev/rtDBG${device_indices[$i]}-1\"; minicom -b 921600 -D /dev/rtDBG${device_indices[$i]}-1')"
done


tmux select-layout even-horizontal
tmux select-pane -t 1

#cd to unkindness test
if $use_unkindness; then
    for ((i=0; i<num_devices; i++)); do
    
        tmux split-window -c "#{pane_current_path}" \
        "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"cd $HOME/dev/unkindess-test && ./bin/devtest --sdk_port /dev/rtDBG${device_indices[$i]}-0 --formation_cycles 100 --formation_cycle_time 15 --formation_time 20\"')"
    
        tmux select-pane -R
    done
fi

#attach to configure app for each device
for ((i=0; i<num_devices; i++)); do

    tmux split-window -c "#{pane_current_path}" \
    "exec bash --rcfile <(echo 'source ~/.bashrc; history -s \"cd $HOME/dev/raven-sdk && ./bin/configure.debug /dev/rtDBG${device_indices[$i]}-0\"; cd $HOME/dev/raven-sdk && ./bin/configure.debug /dev/rtDBG${device_indices[$i]}-0')"

    tmux select-pane -R
done

win_num=$(tmux display-message -p '#I')
echo "Current window: $win_num"

~/bin/scripts/tmux-move-to-front.sh $win_num
