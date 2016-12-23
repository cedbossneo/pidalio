#!/usr/bin/env bash
/opt/bin/kube-controller-manager \
    --master=https://pidalio-apiserver \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    --service-account-private-key-file=/etc/kubernetes/ssl/server-key.pem \
    --pod-eviction-timeout=10s \
    --node-monitor-grace-period=20s \
    --root-ca-file=/etc/kubernetes/ssl/ca.pem
