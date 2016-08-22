#!/usr/bin/env bash
echo "Waiting for Pidalio..."
until curl -s ${PIDALIO_URL}/certs/ca
do
  echo "Trying: ${PIDALIO_URL}"
  sleep 1
done
curl -s ${PIDALIO_URL}/certs/node\?token\=${PIDALIO_TOKEN}\&fqdn=${NODE_FQDN}\&ip=${NODE_IP} > node.json
cat node.json | jq -r .privateKey > /etc/kubernetes/ssl/node-key.pem
cat node.json | jq -r .cert > /etc/kubernetes/ssl/node.pem
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
if [[ "${MASTER}" -eq "true" ]]
then
    # Server Certificate
    curl -s ${PIDALIO_URL}/certs/server\?token\=${PIDALIO_TOKEN}\&ip=${NODE_IP} > server.json
    cat server.json | jq -r .privateKey > /etc/kubernetes/ssl/server-key.pem
    cat server.json | jq -r .cert > /etc/kubernetes/ssl/server.pem

    # Root CA
    curl -s ${PIDALIO_URL}/certs/ca\?token\=${PIDALIO_TOKEN} > ca.json
    cat ca.json | jq -r .cert > /etc/kubernetes/ssl/ca.pem
fi
