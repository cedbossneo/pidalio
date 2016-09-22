#!/usr/bin/env bash
mkdir -p /home/core/.kube
cat <<EOF > /home/core/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
    server: https://pidalio-apiserver
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
/opt/bin/kubelet \
    --network-plugin=cni \
    --network-plugin-dir=/etc/cni/net.d \
    --api-servers=https://piadalio-apiserver \
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
