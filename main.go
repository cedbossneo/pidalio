package main

import (
	"flag"
	"github.com/cedbossneo/pidalio/api"
	"github.com/cedbossneo/pidalio/etcd"
	"github.com/cedbossneo/pidalio/ssl"
)

var (
	etcdUri             = flag.String("etcd-uri", "http://localhost:2379", "ETCD URI")
	token               = flag.String("token", "atleast16charsss", "Token")
	bindAddress         = flag.String("bind-address", "0.0.0.0:3000", "Bind Address")
	domain              = flag.String("domain", "cluster.local", "Kubernetes DNS Domain")
	kubernetesServiceIp = flag.String("kubernetes-service-ip", "10.244.0.1", "Kubernetes Service IP")
)

func init() {
	flag.Parse()
}
func main() {
	etcdClient := etcd.CreateEtcdClient([]string{*etcdUri})
	rootCerts, serverCerts := ssl.LoadCerts(etcdClient, (*token)[0:16], *domain, *kubernetesServiceIp)
	api.CreateAPIServer(rootCerts, serverCerts, *bindAddress)
}
