#!/usr/bin/env bash
/opt/bin/kube-scheduler \
    --master=https://pidalio-apiserver \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml
