#!/usr/bin/env bash
curl -s -XPOST ${PIDALIO_URL}/certs/node\?token\=${PIDALIO_TOKEN}\&id=${NODE_ID}\&ip=${NODE_IP}\&os=linux\&arch=amd64
if [[ "${MASTER}" -eq "true" ]]
then
    /opt/bin/kubelet \
      --docker-endpoint=unix:///var/run/weave/weave.sock \
      --api-servers=http://127.0.0.1:8080 \
      --register-schedulable=${MASTER} \
      --register-node=false \
      --cloud-provider=openstack \
      --cloud-config=/etc/kubernetes/cloud.conf \
      --allow-privileged=true \
      --config=/etc/kubernetes/manifests/master \
      --hostname-override=${NODE_IP} \
      --cluster-dns=10.0.2.2 \
      --cluster-domain=${DOMAIN}
      @*
else
    /opt/bin/kubelet \
      --docker-endpoint=unix:///var/run/weave/weave.sock \
      --api-servers=https://pidalio-master \
      --register-node=false \
      --node-labels=mode=SchedulingDisabled \
      --allow-privileged=true \
      --config=/etc/kubernetes/manifests/node \
      --hostname-override=${NODE_IP} \
      --cloud-provider=openstack \
      --cloud-config=/etc/kubernetes/cloud.conf \
      --cluster-dns=10.0.2.2 \
      --cluster-domain=${DOMAIN} \
      --tls-cert-file=/etc/kubernetes/ssl/node.pem \
      --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
      --kubeconfig=/etc/kubernetes/kubeconfig.yaml
      @*
fi
