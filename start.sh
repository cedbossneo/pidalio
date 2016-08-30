#!/usr/bin/env bash
/opt/pidalio/kube/kubelet/scripts/make-cloud-config.sh
/opt/pidalio/kube/kubelet/scripts/retrieve-certificates.sh
/opt/pidalio/kube/kubelet/scripts/prepare-yaml.sh
/opt/pidalio/kube/kubelet/scripts/launch-kubelet.sh
