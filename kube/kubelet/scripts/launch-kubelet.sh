#!/usr/bin/env bash
if [[ "${MASTER}" == "true" ]]
then
  (
    until curl -m 5 http://localhost:8080/healthz
    do
        echo "Waiting for master to be ready"
        sleep 10
    done
    # Initialize Kubernetes Addons
    /opt/bin/kubectl create -f /etc/kubernetes/descriptors
    # Initialize Ceph
    # /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph.sh
  ) &
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=http://127.0.0.1:8080 \
    --register-schedulable=false \
    --register-node=true \
    --allow-privileged=true \
    --node-ip=${NODE_IP} \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_PUBLIC_IP} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
else
  PIDALIO_URL=http://$(/opt/bin/weave dns-lookup pidalio):3000
  MASTERS_URLS=$(curl -s ${PIDALIO_URL}/k8s/masters\?token\=${PIDALIO_TOKEN} | jq -r .urls[] | tr '\n' ',')
  MASTER_URL=$(curl -s ${PIDALIO_URL}/k8s/masters\?token\=${PIDALIO_TOKEN} | jq -r .urls[] | head -n 1)
  echo Masters: ${MASTERS_URLS}
  mkdir -p /home/core/.kube
  cat <<EOF > /home/core/.kube/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
    server: ${MASTER_URL}
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
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=${MASTERS_URLS} \
    --register-node=true \
    --node-labels=mode=SchedulingDisabled,type=${NODE_TYPE} \
    --allow-privileged=true \
    --node-ip=${NODE_IP} \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_PUBLIC_IP} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    @*
fi
