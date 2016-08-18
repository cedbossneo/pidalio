#!/usr/bin/env bash
cat <<EOF > /etc/kubernetes/cloud.conf
[Global]
auth-url=$OS_AUTH_URL
username=$OS_USERNAME
password=$OS_PASSWORD
region=$OS_REGION
tenant-id=$OS_PROJECT_ID
[LoadBalancer]
subnet-id = $OS_SUBNET
EOF
