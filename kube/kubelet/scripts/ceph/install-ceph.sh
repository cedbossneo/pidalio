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
echo AQBmqFtYAAAAABAARfax/BYvY8leNbtxNc7o/Q== > ceph-client-key
echo AQDP299XAAAAABAA9ut3smkroIdHsYCfqf5YWQ== > ceph-admin-key
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create namespace ceph
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create namespace monitoring
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create secret generic ceph-conf-combined --from-file=ceph.conf --from-file=ceph.client.admin.keyring --from-file=ceph.client.user.keyring --from-file=ceph.mon.keyring --namespace=ceph
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create secret generic ceph-bootstrap-rgw-keyring --from-file=ceph.keyring=ceph.rgw.keyring --namespace=ceph
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create secret generic ceph-bootstrap-mds-keyring --from-file=ceph.keyring=ceph.mds.keyring --namespace=ceph
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create secret generic ceph-bootstrap-osd-keyring --from-file=ceph.keyring=ceph.osd.keyring --namespace=ceph
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create secret generic ceph-admin-key --type="kubernetes.io/rbd" --from-file=ceph-admin-key --namespace=ceph
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create secret generic ceph-client-key --type="kubernetes.io/rbd" --from-file=ceph-client-key --namespace=monitoring
/opt/bin/kubectl --kubeconfig=/home/core/.kube/config create secret generic ceph-client-key --type="kubernetes.io/rbd" --from-file=ceph-client-key
