#!/usr/bin/env bash
if [[ "${MASTER}" == "true" ]]
then
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --register-node=false \
    --allow-privileged=true \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_IP} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
else
  PIDALIO_URL=http://$(/opt/bin/weave dns-lookup pidalio):3000
  MASTERS_URLS=$(curl -s ${PIDALIO_URL}/k8s/masters\?token\=${PIDALIO_TOKEN} | jq -r .urls[] | tr '\n' ',')
  echo Masters: ${MASTERS_URLS}
  until [[ "$(curl --write-out '%{http_code}' --silent --output /dev/null -XPOST $PIDALIO_URL/register/node\?token\=$PIDALIO_TOKEN\&id=$NODE_ID\&ip=$NODE_IP\&os=linux\&arch=amd64)" == "200" ]]
  do
        echo "Trying to register node"
        sleep 10
  done
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=${MASTERS_URLS} \
    --register-node=false \
    --node-labels=mode=SchedulingDisabled \
    --allow-privileged=true \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_IP} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --tls-cert-file=/etc/kubernetes/ssl/node.pem \
    --tls-private-key-file=/etc/kubernetes/ssl/node-key.pem \
    --cloud-provider=openstack \
    --cloud-config=/etc/kubernetes/cloud.conf \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
fi
