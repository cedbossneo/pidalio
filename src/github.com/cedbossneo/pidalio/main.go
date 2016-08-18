package main

import (
	"github.com/cedbossneo/pidalio/etcd"
	"github.com/cedbossneo/pidalio/ssl"
	"github.com/cedbossneo/pidalio/api"
)

func main() {
	etcd := etcd.CreateEtcdClient([]string{"http://localhost:2379"})
	rootCerts := ssl.LoadRootCerts(etcd, "aaaaaaaaaaaaaaaa")
	api.CreateAPIServer(rootCerts)
}
