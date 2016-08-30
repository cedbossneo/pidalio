#!/usr/bin/env bash
set -xe
source /etc/pidalio.env
# Configure ETCD
if cat /etc/etcd.env | grep ETCD_NAME; then exit 0; fi
if [[ "$PEERS" == "$NODE_IP" ]]
then
    cat <<EOF > /etc/etcd.env
ETCD_ADVERTISE_CLIENT_URLS=http://${NODE_IP}:2379,http://${NODE_PUBLIC_IP}:2379
ETCD_INITIAL_ADVERTISE_PEER_URLS=http://${NODE_IP}:2380,http://${NODE_PUBLIC_IP}:2380
ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
ETCD_NAME=${NODE_FQDN}
ETCD_INITIAL_CLUSTER=${NODE_FQDN}=http://${NODE_IP}:2380,${NODE_FQDN}=http://${NODE_PUBLIC_IP}:2380
ETCD_INITIAL_CLUSTER_STATE=new
EOF
else
    ETCD_PEERS=""
    for server in ${PEERS}
    do
      ETCD_PEERS=http://${server}:2379,${ETCD_PEERS}
    done
    ETCD_PEERS=$(echo ${ETCD_PEERS}|sed -rn 's/^(.*),$/\1/p')
    echo "EtcD peers: $ETCD_PEERS"
    until etcdctl --no-sync --endpoints ${ETCD_PEERS} ls >/dev/null 2>&1; do
        echo "Waiting for EtcD at $ETCD_PEERS..."
        sleep 10
    done
    until cat /etc/etcd.env | grep ETCD_NAME
    do
        echo "Try to register node"
        etcdctl --endpoints ${ETCD_PEERS} member add ${NODE_FQDN} http://${NODE_PUBLIC_IP}:2380 | tail -n +3 > /etc/etcd.env
    done
    cat <<EOF >> /etc/etcd.env
ETCD_ADVERTISE_CLIENT_URLS=http://${NODE_IP}:2379,http://${NODE_PUBLIC_IP}:2379
ETCD_INITIAL_ADVERTISE_PEER_URLS=http://${NODE_IP}:2380,http://${NODE_PUBLIC_IP}:2380
ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
EOF
fi

# Create directories and download Kubernetes Components
mkdir -p /etc/kubernetes/descriptors /etc/kubernetes/manifests /etc/kubernetes/ssl /opt/bin
if [[ -x /opt/bin/kubelet ]]; then
    echo "Kubelet already installed"
else
    curl -o /opt/bin/kubelet http://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubelet
    chmod +x /opt/bin/kubelet
fi
if [[ -x /opt/bin/kubectl ]]; then
    echo "Kubectl already installed"
else
    curl -o /opt/bin/kubectl http://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubectl
    chmod +x /opt/bin/kubectl
fi
