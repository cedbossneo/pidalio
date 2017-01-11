#!/usr/bin/env bash
source /etc/pidalio.env
echo "Setting DNS"
WEAVE_DNS_ADDRESS=$(/opt/bin/weave report | jq -r .DNS.Address | cut -d ':' -f 1)
until [[ "$WEAVE_DNS_ADDRESS" != "" ]];
do
    WEAVE_DNS_ADDRESS=$(/opt/bin/weave report | jq -r .DNS.Address | cut -d ':' -f 1)
    sleep 5
done
cat <<EOF > /opt/resolv.conf
nameserver ${WEAVE_DNS_ADDRESS}
nameserver ${PROVIDER_DNS}
EOF
rm -f /etc/resolv.conf
ln -s /opt/resolv.conf /etc/resolv.conf
