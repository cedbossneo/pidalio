#!/usr/bin/env bash
MASTERS_URLS=""
MASTER_URL=""
until [[ "$(/opt/bin/weave dns-lookup pidalio-apiserver | wc -l)" == "1" ]]
do
    echo "Waiting for master"
    sleep 10
done
for master in $(/opt/bin/weave dns-lookup pidalio-apiserver)
do
    MASTER_URL=https://${master}
done
i=0
until [[ "$(curl -s -m 5 -k --cert /etc/kubernetes/ssl/node.pem --key /etc/kubernetes/ssl/node-key.pem $MASTER_URL/healthz)" == "ok" || $i == 5 ]]
do
    echo "Waiting for master to be healthy"
    i=$(expr $i + 1)
    sleep 10
done
if [[ $i == 5 ]]; then exit 1; fi
(
    while [[ "$(curl -s -m 5 -k --cert /etc/kubernetes/ssl/node.pem --key /etc/kubernetes/ssl/node-key.pem $MASTER_URL/healthz)" == "ok" ]]
    do
        sleep 10
    done
    pkill kube-proxy
) &
/opt/bin/kube-proxy \
    --master=${MASTER_URL} \
    --hostname-override=${NODE_PUBLIC_IP} \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    --proxy-mode=iptables
