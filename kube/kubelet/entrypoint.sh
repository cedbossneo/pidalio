#!/usr/bin/env bash
# REQUIRED ENV VARIABLES
# PIDALIO_URL
# PIDALIO_TOKEN
# MASTER
# NODE_IP
# NODE_FQDN
# NODE_ID
# DOMAIN
# OS_AUTH_URL
# OS_USERNAME
# OS_PASSWORD
# OS_REGION
# OS_PROJECT_ID
# OS_SUBNET

mkdir -p /etc/kubernetes/descriptors /etc/kubernetes/manifests
cd /run
./make-cloud-config.sh
./retrieve-certificates.sh
./launch-kubelet.sh
./prepare-yaml.sh
