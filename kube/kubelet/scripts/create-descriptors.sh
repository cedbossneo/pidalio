#!/usr/bin/env bash
i=0
until curl -m 5 http://localhost:8080/healthz || [[ $i == 5 ]]
do
    echo "Waiting for master to be ready"
    sleep 10
    i=$(expr $i + 1)
done
if [[ $i == 5 ]]; then exit 1; fi
# Initialize Kubernetes Addons
/opt/bin/kubectl create -f /etc/kubernetes/descriptors/dns
# Initialize Ceph
if [[ "${CEPH}" == "True" ]]
then
    /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph.sh
    /opt/bin/kubectl create -f /etc/kubernetes/descriptors/ceph --namespace=ceph
fi
# Initialize Monitoring
if [[ "${MONITORING}" == "True" ]]
then
    /opt/bin/kubectl create namespace monitoring
    /opt/bin/kubectl create -f /etc/kubernetes/descriptors/monitoring --namespace=monitoring
fi
exit 0
