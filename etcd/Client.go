package etcd

import (
	"github.com/coreos/etcd/client"
	"golang.org/x/net/context"
	"log"
	"time"
)

type EtcdClient struct {
	keys   client.KeysAPI
	client client.Client
}

func CreateEtcdClient(uris []string) EtcdClient {
	cfg := client.Config{
		Endpoints:               uris,
		Transport:               client.DefaultTransport,
		HeaderTimeoutPerRequest: time.Second,
	}
	if c, err := client.New(cfg); err != nil {
		log.Fatal(err)
	}
	return EtcdClient{
		keys:   client.NewKeysAPI(c),
		client: c,
	}
}

func (etcd EtcdClient) SetKey(key, value string) error {
	log.Printf("Setting %s with %s value\n", key, value)
	if resp, err := etcd.keys.Set(context.Background(), key, value, nil); err != nil {
		return err
	}
	log.Printf("Set is done. Metadata is %q\n", resp)
	return nil
}

func (etcd EtcdClient) CreateKey(key, value string) error {
	log.Printf("Creating %s with %s value\n", key, value)
	if resp, err := etcd.keys.Create(context.Background(), key, value); err != nil {
		return err
	}
	log.Printf("Create is done. Metadata is %q\n", resp)
	return nil
}

func (etcd EtcdClient) GetKey(key string) (string, error) {
	log.Printf("Getting %s value\n", key)
	if resp, err := etcd.keys.Get(context.Background(), key, nil); err != nil {
		return nil, err
	}
	log.Printf("Get is done. Metadata is %q\n", resp)
	log.Printf("%q key has %q value\n", resp.Node.Key, resp.Node.Value)
	return resp.Node.Value, nil
}

func (etcd EtcdClient) ListKeys(key string) (client.Nodes, error) {
	log.Printf("Listing %s value\n", key)
	if resp, err := etcd.keys.Get(context.Background(), key, nil); err != nil || !resp.Node.Dir {
		return nil, err
	}
	log.Printf("Get is done. Metadata is %q\n", resp)
	return resp.Node.Nodes, nil
}

func (etcd EtcdClient) KeyExist(key string) bool {
	log.Printf("Test %s exist\n", key)
	_, err := etcd.keys.Get(context.Background(), key, nil)
	return err == nil
}
