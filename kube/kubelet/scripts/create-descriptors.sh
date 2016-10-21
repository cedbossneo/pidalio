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
    if [[ "${MONITORING}" == "True" ]]
    then
        until [ "$(/opt/bin/kubectl get pods --namespace=ceph | tail -n +2 | egrep -v '(.*)1/1(.*)Running' | wc -l)" == "0" ]
        do
          echo "Waiting for ceph to be ready"
          sleep 10
        done
        echo "Creating monitoring disk in ceph"
        until /opt/bin/rbd -m ceph-mon.ceph info prometheus
        do
          /opt/bin/rbd -m ceph-mon.ceph create prometheus --size=50G
        done
        until /opt/bin/rbd -m ceph-mon.ceph info grafana
        do
          /opt/bin/rbd -m ceph-mon.ceph create grafana --size=1G
        done
        /opt/bin/kubectl create -f /etc/kubernetes/descriptors/monitoring --namespace=monitoring
    fi
fi
exit 0
