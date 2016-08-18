package etcd

import (
	"log"
	"time"
	"golang.org/x/net/context"
	"github.com/coreos/etcd/client"
)

type EtcdClient struct {
	keys client.KeysAPI
	client client.Client
}

func CreateEtcdClient(uris []string) EtcdClient  {
	cfg := client.Config{
		Endpoints:               uris,
		Transport:               client.DefaultTransport,
		HeaderTimeoutPerRequest: time.Second,
	}
	c, err := client.New(cfg)
	if err != nil {
		log.Fatal(err)
	}
	return EtcdClient{
		keys: client.NewKeysAPI(c),
		client: c,
	}
}

func (etcd EtcdClient) SetKey(key string, value string) {
	log.Print("Setting ", key, " with ",value," value")
	resp, err := etcd.keys.Set(context.Background(), key, value, nil)
	if err != nil {
		log.Fatal(err)
	} else {
		log.Printf("Set is done. Metadata is %q\n", resp)
	}
}

func (etcd EtcdClient) CreateKey(key string, value string) {
	log.Print("Creating ", key, " with ",value," value")
	resp, err := etcd.keys.Create(context.Background(), key, value)
	if err != nil {
		log.Fatal(err)
	} else {
		log.Printf("Create is done. Metadata is %q\n", resp)
	}
}

func (etcd EtcdClient) GetKey(key string) string {
	log.Print("Getting ", key, " value")
	resp, err := etcd.keys.Get(context.Background(), key, nil)
	if err != nil {
		log.Fatal(err)
	} else {
		log.Printf("Get is done. Metadata is %q\n", resp)
		log.Printf("%q key has %q value\n", resp.Node.Key, resp.Node.Value)
	}
	return resp.Node.Value
}

func (etcd EtcdClient) KeyExist(key string) bool {
	log.Print("Test ", key, " exist")
	_, err := etcd.keys.Get(context.Background(), key, nil)
	return err == nil
}
