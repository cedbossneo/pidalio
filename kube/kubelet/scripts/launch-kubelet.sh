#!/usr/bin/env bash
MASTERS_URLS=""
MASTER_URL=""
until [[ "$(/opt/bin/weave dns-lookup pidalio-apiserver | wc -l)" == "1" ]]
do
    echo "Waiting for master"
    sleep 10
done
for master in $(/opt/bin/weave dns-lookup pidalio-apiserver)
do
    MASTER_URL=https://${master}
done
i=0
until [[ "$(curl -s -m 5 -k --cert /etc/kubernetes/ssl/node.pem --key /etc/kubernetes/ssl/node-key.pem $MASTER_URL/healthz)" == "ok" || $i == 5 ]]
do
    echo "Waiting for master to be healthy"
    i=$(expr $i + 1)
    sleep 10
done
if [[ $i == 5 ]]; then exit 1; fi
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
    for i in {1..3}
    do
        while [[ "$(curl -s -m 10 -k --cert /etc/kubernetes/ssl/node.pem --key /etc/kubernetes/ssl/node-key.pem $MASTER_URL/healthz)" == "ok" ]]
        do
            sleep 10
        done
        echo "APIServer not healthy, try $i/3"
    done
    echo "APIServer not healthy, exiting"
    pkill kubelet
) &
/opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=${MASTER_URL} \
    --register-node=true \
    --node-labels=type=${NODE_TYPE} \
    --allow-privileged=true \
    --node-ip=${NODE_IP} \
    --hostname-override=${NODE_PUBLIC_IP} \
    --cluster-dns=10.244.0.3 \
    --cluster-domain=${DOMAIN} \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem
