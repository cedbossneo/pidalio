#!/usr/bin/env bash
/opt/bin/kube-proxy \
  --master=https://pidalio-apiserver \
  --hostname-override=${NODE_PUBLIC_IP} \
  --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
  --proxy-mode=iptables
