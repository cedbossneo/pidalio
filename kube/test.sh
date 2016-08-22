#!/usr/bin/env bash
eval $(weave env)
source /etc/environment
export OS_AUTH_URL=https://identity.fr1.cloudwatt.com/v2.0
export OS_TENANT_NAME="0750179922_compute_buy"
export OS_USERNAME="cedric.hauber@wescale.fr"
export OS_PASSWORD="wescalewescale"
export OS_REGION_NAME="fr1"
export OS_TENANT_ID=67776479fd524682899ed9931dd1a742

docker rm -f pidalio pidalio-master

docker run -d --name=pidalio \
    -e TOKEN=aaaaaaaaaaaaaaaa \
    -e ETCD_URI=http://${COREOS_PRIVATE_IPV4}:2379
    -e K8S_URI=http://${COREOS_PRIVATE_IPV4}:8080 \
    -e OS_REGION_NAME=$OS_REGION_NAME \
    -e OS_AUTH_URL=$OS_AUTH_URL \
    -e OS_PASSWORD=$OS_PASSWORD \
    -e OS_USERNAME=$OS_USERNAME \
    -e OS_TENANT_NAME=$OS_TENANT_NAME \
    cedbossneo/pidalio

docker run -d --privileged --net=host --name=pidalio-master \
    -e PIDALIO_URL=http://pidalio:3000 \
    -e PIDALIO_TOKEN=aaaaaaaaaaaaaaaa \
    -e MASTER=true \
    -e NODE_IP=${COREOS_PRIVATE_IPV4} \
    -e NODE_FQDN=$(hostname) \
    -e NODE_ID=xxx \
    -e DOMAIN=cluster.local \
    -e OS_REGION_NAME=$OS_REGION_NAME \
    -e OS_AUTH_URL=$OS_AUTH_URL \
    -e OS_PASSWORD=$OS_PASSWORD \
    -e OS_USERNAME=$OS_USERNAME \
    -e OS_TENANT_NAME=$OS_TENANT_NAME \
    -e OS_PROJECT_ID=$OS_TENANT_ID \
    -e OS_SUBNET=toto \
    cedbossneo/pidalio-kube
