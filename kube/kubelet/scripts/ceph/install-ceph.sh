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
/opt/bin/kubectl create \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-mds-v1-dp.yaml \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-mon-v1-svc.yaml \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-mon-v1-dp.yaml \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-mon-check-v1-dp.yaml \
-f /opt/pidalio/kube/kubelet/scripts/ceph/yaml/ceph-osd-v1-ds.yaml \
--namespace=ceph
