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
    /opt/pidalio/kube/kubelet/scripts/ceph/install-ceph.sh
  ) &
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=http://127.0.0.1:8080 \
    --register-schedulable=false \
    --register-node=true \
    --allow-privileged=true \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_NAME} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --cloud-provider=openstack \
    --cloud-config=/etc/kubernetes/cloud.conf \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
else
  PIDALIO_URL=http://$(/opt/bin/weave dns-lookup pidalio):3000
  MASTERS_URLS=$(curl -s ${PIDALIO_URL}/k8s/masters\?token\=${PIDALIO_TOKEN} | jq -r .urls[] | tr '\n' ',')
  echo Masters: ${MASTERS_URLS}
  /opt/bin/kubelet \
    --docker-endpoint=unix:///var/run/weave/weave.sock \
    --api-servers=${MASTERS_URLS} \
    --register-node=true \
    --node-labels=mode=SchedulingDisabled \
    --allow-privileged=true \
    --config=/etc/kubernetes/manifests \
    --hostname-override=${NODE_NAME} \
    --cluster-dns=10.16.0.3 \
    --cluster-domain=${DOMAIN} \
    --cloud-provider=openstack \
    --cloud-config=/etc/kubernetes/cloud.conf \
    --kubeconfig=/etc/kubernetes/kubeconfig.yaml \
    @*
fi
