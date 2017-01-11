#!/usr/bin/env bash
if [[ "${PROVIDER}" == "gce" ]]
then
    cat <<EOF > /etc/pidalio/provider.config
[global]

EOF
fi