#!/bin/bash
set -e

if [[ -n "${_SSH_DISPLAY}" ]]; then
    export DISPLAY=${_SSH_DISPLAY}
fi

mkdir -p ~/tmp
tee ~/tmp/tmux-clipboard.txt | xclip -in -selection clipboard
