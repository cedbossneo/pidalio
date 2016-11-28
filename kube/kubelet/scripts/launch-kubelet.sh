#!/usr/bin/env bash
mkdir -p /home/core/.kube
cat <<EOF > /home/core/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
    server: https://10.42.1.1
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
export DOCKER_HOST=unix:///var/run/weave/weave.sock
/usr/bin/docker pull quay.io/coreos/hyperkube:v1.4.6_coreos.0
/usr/bin/docker run \
    --volume /etc/cni:/etc/cni \
    --volume /var/log:/var/log \
    --volume /etc/kubernetes:/etc/kubernetes \
    --volume /usr/share/ca-certificates:/etc/ssl/certs \
    --volume /opt/pidalio/weave.dns:/etc/resolv.conf \
    --net=host \
    --privileged \
    --rm \
    --name=pidalio-node \
    quay.io/coreos/hyperkube:v1.4.6_coreos.0 \
    /hyperkube \
    kubelet \
    --network-plugin=cni \
    --network-plugin-dir=/etc/cni/net.d \
    --api-servers=https://pidalio-apiserver \
    --register-node=true \
    --node-labels=type=${NODE_TYPE},storage=${NODE_STORAGE} \
    --allow-privileged=true \
    --node-ip=${NODE_IP} \
    --hostname-override=${NODE_PUBLIC_IP} \
    --cluster-dns=10.244.0.3 \
    --cluster-domain=${DOMAIN} \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem
