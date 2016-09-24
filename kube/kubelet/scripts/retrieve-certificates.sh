#!/usr/bin/env bash
echo "Waiting for Pidalio..."
until [[ "$(/opt/bin/weave dns-lookup pidalio|/usr/bin/wc -l)" == "1" ]]
do
    echo "Waiting for Pidalio"
    sleep 10
done
PIDALIO_URL=http://$(/opt/bin/weave dns-lookup pidalio):3000
until curl -s ${PIDALIO_URL}/certs/ca\?token\=${PIDALIO_TOKEN}
do
    echo "Trying: ${PIDALIO_URL}"
    sleep 1
done
# Root CA
if [ ! -e /etc/kubernetes/ssl/ca.pem ]; then
    curl -s ${PIDALIO_URL}/certs/ca\?token\=${PIDALIO_TOKEN} > ca.json
    cat ca.json | jq -r .cert > /etc/kubernetes/ssl/ca.pem
fi
if [[ "${MASTER}" == "true" ]]
then
  curl -s http://pidalio:3000/certs/server\?token\=${PIDALIO_TOKEN}\&ip=10.10.1.1 > server.json
  cat server.json | jq -r .privateKey > /etc/kubernetes/ssl/server-key.pem
  cat server.json | jq -r .cert > /etc/kubernetes/ssl/server.pem
fi
if [ ! -e /etc/kubernetes/ssl/node.pem ]; then
    curl -s ${PIDALIO_URL}/certs/node\?token\=${PIDALIO_TOKEN}\&fqdn=${NODE_FQDN}\&ip=${NODE_PUBLIC_IP} > node.json
    cat node.json | jq -r .privateKey > /etc/kubernetes/ssl/node-key.pem
    cat node.json | jq -r .cert > /etc/kubernetes/ssl/node.pem
fi
cat <<EOF > /etc/kubernetes/kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- name: local
  cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
users:
- name: kubelet
  user:
    client-certificate: /etc/kubernetes/ssl/node.pem
    client-key: /etc/kubernetes/ssl/node-key.pem
contexts:
- context:
    cluster: local
    user: kubelet
  name: kubelet-context
current-context: kubelet-context
EOF
