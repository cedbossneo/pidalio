#!/usr/bin/env bash
mkdir -p /etc/kubernetes/descriptors /etc/kubernetes/manifests
./make-cloud-config.sh
./retrieve-certificates.sh
