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
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create -f /etc/kubernetes/descriptors/dns
# Initialize Ceph
if [[ "${CEPH}" == "True" ]]
then
    /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph.sh
    if [[ "${CEPH_DISK}" == "True" ]]
    then
        /opt/bin/kubectl --kubeconfig=/home/core/.kube/config --namespace=ceph create \
        -f /etc/kubernetes/descriptors/ceph/ceph-mds-v1-dp.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-mon-check-v1-dp.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-mon-v1-dp.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-mon-v1-svc.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-osd-v1-ds-disk.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-sc.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-stats-v1-dp.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-stats-v1-svc.yaml
    else
        /opt/bin/kubectl --kubeconfig=/home/core/.kube/config --namespace=ceph create \
        -f /etc/kubernetes/descriptors/ceph/ceph-mds-v1-dp.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-mon-check-v1-dp.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-mon-v1-dp.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-mon-v1-svc.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-osd-v1-ds-dir.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-sc.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-stats-v1-dp.yaml \
        -f /etc/kubernetes/descriptors/ceph/ceph-stats-v1-svc.yaml
    fi
    if [[ "${MONITORING}" == "True" ]]
    then
        until [ "$(/opt/bin/kubectl --kubeconfig=/home/core/.kube/config get pods --namespace=ceph | tail -n +2 | egrep -v '(.*)1/1(.*)Running' | wc -l)" == "0" ]
        do
          echo "Waiting for ceph to be ready"
          sleep 10
        done
        echo "Creating monitoring disk in ceph"
        until /opt/bin/rbd -m ceph-mon.ceph info prometheus
        do
          /opt/bin/rbd -m ceph-mon.ceph create prometheus --size=50G
          sleep 10
        done
        until /opt/bin/rbd -m ceph-mon.ceph info grafana
        do
          /opt/bin/rbd -m ceph-mon.ceph create grafana --size=1G
          sleep 10
        done
        /opt/bin/kubectl --kubeconfig=/home/core/.kube/config create -f /etc/kubernetes/descriptors/monitoring --namespace=monitoring
    fi
fi
exit 0
