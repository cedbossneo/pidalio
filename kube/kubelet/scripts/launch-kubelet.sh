#!/usr/bin/env bash
MASTERS_URLS=""
MASTER_URL=""
for master in $(/opt/bin/weave dns-lookup pidalio-apiserver)
do
    MASTER_URL=https://${master}
done
mkdir -p /home/core/.kube
cat <<EOF > /home/core/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
    server: $MASTER_URL
  name: local
contexts:
- context:
    cluster: local
    user: local
  name: local
current-context: local
kind: Config
preferences: {}
users:
- name: local
  user:
    client-certificate: /etc/kubernetes/ssl/node.pem
    client-key: /etc/kubernetes/ssl/node-key.pem
EOF
chown -R core:core /home/core/.kube
(
    while [ "$(curl -s -m 5 $MASTER_URL/healthz)" == "ok" ]
    do
        sleep 10
    done
    pkill kubelet
) &
/opt/bin/kubelet \
    --network-plugin=cni \
    --network-plugin-dir=/etc/cni/net.d \
    --api-servers=${MASTER_URL} \
    --register-node=true \
    --node-labels=mode=SchedulingDisabled,type=${NODE_TYPE} \
    --allow-privileged=true \
    --node-ip=${NODE_IP} \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_PUBLIC_IP} \
    --cluster-dns=10.244.0.3 \
    --cluster-domain=${DOMAIN} \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    @*
