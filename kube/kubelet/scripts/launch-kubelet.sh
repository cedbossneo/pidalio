#!/usr/bin/env bash
mkdir -p /home/core/.kube
cat <<EOF > /home/core/.kube/config
apiVersion: v1
clusters:
- cluster:
    server: http://pidalio-apiserver:8080
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
EOF
chown -R core:core /home/core/.kube
echo "Setting DNS"
WEAVE_DNS_ADDRESS=$(/opt/bin/weave report | jq -r .DNS.Address | cut -d ':' -f 1)
until [[ "$WEAVE_DNS_ADDRESS" != "" ]];
do
    WEAVE_DNS_ADDRESS=$(/opt/bin/weave report | jq -r .DNS.Address | cut -d ':' -f 1)
    sleep 5
done
cat <<EOF > /opt/resolv.conf
nameserver ${WEAVE_DNS_ADDRESS}
nameserver 185.23.94.244
EOF
rm -f /etc/resolv.conf
ln -s /opt/resolv.conf /etc/resolv.conf
/opt/bin/kubelet \
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
