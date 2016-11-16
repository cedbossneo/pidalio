# Pidalio

Pidalio is a new way to deploy High-aviability and multi-providers Kubernetes Stack

It runs on CoreOS end shipped with out of the box Ceph Cluster and Prometheus Monitoring.

You can extend your cluster on multiple Cloud Providers just by launching new Coreos Nodes.

It has been tested on OpenStack, Google Compute Engine, Baremetal (for hybrid cluster) and AWS.

More documentation soon.

Have a look at the templates directory for cloud-config files.

These variables must be changed in templates are:

$PEER$ : The list of nodes in you group
$TOKEN$ : A unique token (must be at least 16 chars

Peer must be at least 3 public / private ips of nodes
