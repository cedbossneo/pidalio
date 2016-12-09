# Pidalio

Pidalio is a new way to deploy HA and multi-providers Kubernetes Stack

It runs on CoreOS and shipped with Ceph Cluster and Prometheus Monitoring out of the box.

You can extend your cluster on multiple Cloud Providers or regions just by launching new Coreos Nodes and thell them to join existing peers.

It has been tested on OpenStack, Google Compute Engine, Baremetal (for hybrid cluster) and AWS.

Have a look at the templates directory for cloud-config files.

These variables must be changed in templates are:

$PEER$ : The list of nodes to join

$TOKEN$ : A unique token (must be at least 16 chars)

Peer must be at least 3 public / private ips of nodes

More documentation soon.
