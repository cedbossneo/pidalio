#!/usr/bin/env bash
mkdir -p /etc/ceph
TMP=$(mktemp -d)
FS_ID=$(uuidgen)
cd $TMP
cp /opt/pidalio/kube/kubelet/scripts/ceph/keys/* .
for file in $(ls *)
do
    sed -i s/\\\$token\\\$/${PIDALIO_TOKEN}/g ${file}
    sed -i s/\\\$fsid\\\$/${FS_ID}/g ${file}
done
echo AQDP299XAAAAABAA9ut3smkroIdHsYCfqf5YWQ== > ceph-client-key
/opt/bin/kubectl create namespace ceph
/opt/bin/kubectl create secret generic ceph-conf-combined --from-file=ceph.conf --from-file=ceph.client.admin.keyring --from-file=ceph.mon.keyring --namespace=ceph
/opt/bin/kubectl create secret generic ceph-bootstrap-rgw-keyring --from-file=ceph.keyring=ceph.rgw.keyring --namespace=ceph
/opt/bin/kubectl create secret generic ceph-bootstrap-mds-keyring --from-file=ceph.keyring=ceph.mds.keyring --namespace=ceph
/opt/bin/kubectl create secret generic ceph-bootstrap-osd-keyring --from-file=ceph.keyring=ceph.osd.keyring --namespace=ceph
/opt/bin/kubectl create secret generic ceph-client-key --from-file=ceph-client-key --namespace=ceph
/opt/bin/kubectl create secret generic ceph-client-key --from-file=ceph-client-key
echo "Select at least one instance of my region to be a storage node"
STORAGE_NODE=""
until [[ "$STORAGE_NODE" != "" ]]
do
    STORAGE_NODE=$(/opt/bin/kubectl get nodes -o json | /usr/bin/jq -r ".items[] | select(.metadata.labels.type==\"$REGION\") | select(.status.conditions[].type==\"Ready\") | select(.status.conditions[].status==\"True\") | select(.metadata.labels.storage!=\"true\") | .metadata.name" | head -n 1)
    sleep 10
done
/opt/bin/kubectl label node $STORAGE_NODE storage=true
/opt/bin/kubectl create \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-mds-v1-dp.yaml \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-mon-v1-svc.yaml \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-mon-v1-dp.yaml \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-mon-check-v1-dp.yaml \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-osd-v1-ds.yaml \
--namespace=ceph
