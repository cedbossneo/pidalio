#!/usr/bin/env bash
MY_IP=$(ip -4 addr show scope global dev ethwe | grep inet | cut -d / -f 1 | sed "s/[a-zA-Z ]//g")
/hyperkube \
    apiserver \
    --advertise-address=${MY_IP} \
    $@
