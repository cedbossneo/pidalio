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
# Initialize SC
if [[ "${PROVIDER}" == "gce" ]]
then
cat <<EOF | kubectl create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
name: provider
provisioner: kubernetes.io/gce-pd
parameters:
type: pd-standard
zone: ${PROVIDER_ZONE}
EOF

fi
# Initialize Ceph
if [[ "${CEPH}" == "True" ]]
then
    /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph.sh
    /opt/bin/kubectl --kubeconfig=/home/core/.kube/config --namespace=ceph create \
    -f /etc/kubernetes/descriptors/ceph/ceph-mds-v1-dp.yaml \
    -f /etc/kubernetes/descriptors/ceph/ceph-mon-check-v1-dp.yaml \
    -f /etc/kubernetes/descriptors/ceph/ceph-mon-v1-dp.yaml \
    -f /etc/kubernetes/descriptors/ceph/ceph-mon-v1-svc.yaml \
    -f /etc/kubernetes/descriptors/ceph/ceph-sc.yaml
    if [[ "${CEPH_TYPE}" == "disk" ]]
    then
        /opt/bin/kubectl --kubeconfig=/home/core/.kube/config --namespace=ceph create \
        -f /etc/kubernetes/descriptors/ceph/ceph-osd-v1-ds-disk.yaml
    fi
    if [[ "${CEPH_TYPE}" == "directory" ]]
    then
        /opt/bin/kubectl --kubeconfig=/home/core/.kube/config --namespace=ceph create \
        -f /etc/kubernetes/descriptors/ceph/ceph-osd-v1-ds-dir.yaml
    fi
    if [[ "${CEPH_TYPE}" == "dynamic" ]]
    then
        /opt/bin/kubectl --kubeconfig=/home/core/.kube/config --namespace=ceph create \
        -f /etc/kubernetes/descriptors/ceph/ceph-osd-v1-sfs.yaml
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
