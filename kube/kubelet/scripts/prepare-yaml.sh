#!/usr/bin/env bash
if [[ "${MASTER}" == "true" ]]
then
  cp /opt/kube/manifests/master/* /etc/kubernetes/manifests
else
  cp /opt/kube/manifests/node/* /etc/kubernetes/manifests

  echo "Waiting for Kubernetes..."
  PIDALIO_URL=http://$(/opt/bin/weave dns-lookup pidalio):3000
  until [[ "curl --write-out '%{http_code}' --silent --output /dev/null $PIDALIO_URL/k8s/masters\?token\=${PIDALIO_TOKEN}" == "200" ]]
  do
    echo "Trying: $PIDALIO_URL/k8s/masters"
    sleep 10
  done
  export MASTERS_URLS=$(curl -s $PIDALIO_URL/k8s/masters\?token\=${PIDALIO_TOKEN} | jq -r .urls | tr '\n' ',')
  export MASTER_URL=$(curl -s $PIDALIO_URL/k8s/masters\?token\=${PIDALIO_TOKEN} | jq -r .urls | head -n 1)
fi
cp /opt/kube/descriptors/* /etc/kubernetes/descriptors
for file in $(ls /etc/kubernetes/descriptors/*.yaml /etc/kubernetes/manifests/*.yaml)
do
    sed -i s/\\\$master\\\$/${MASTER_URL}/g $file
    sed -i s/\\\$domain\\\$/${DOMAIN}/g $file
    sed -i s/\\\$private_ipv4\\\$/${NODE_IP}/g $file
done
