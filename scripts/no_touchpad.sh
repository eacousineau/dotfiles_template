#!/bin/bash
set -eux

enabled=0
if [[ $# -eq 1 ]]; then
    enabled=${1}
fi

id=$(xinput list | grep Synaptics | sed -r 's#.*id=([0-9]+).*#\1#')
xinput set-prop ${id} "Device Enabled" ${enabled}
