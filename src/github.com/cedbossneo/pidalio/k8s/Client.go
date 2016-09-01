package k8s

import (
	"fmt"
	"os"
	"github.com/YakLabs/k8s-client"
	"github.com/YakLabs/k8s-client/http"
	"log"
	"github.com/cedbossneo/pidalio/ssl"
	"github.com/cedbossneo/pidalio/etcd"
	"encoding/json"
	"strings"
)

func FetchMastersIPs(etcdClient etcd.EtcdClient) ([]string, []string, error){
	var masterStateJSON map[string]interface{}
	var machineStateJSON map[string]interface{}
	var ips []string
	var urls []string
	mastersStates, err  := etcdClient.ListKeys("/_coreos.com/fleet/state/")
	if err != nil {
		return nil, nil, err
	}
	for i := 0; i < len(mastersStates); i++ {
		if !strings.Contains(mastersStates[i].Key, "pidalio-master") {
			continue
		}
		json.Unmarshal([]byte(mastersStates[i].Value), &masterStateJSON);
		masterMachineID := masterStateJSON["machineState"].(map[string]interface{})["ID"].(string)
		machineState, err := etcdClient.GetKey("/_coreos.com/fleet/machines/"+ masterMachineID +"/object")
		if err != nil {
			return nil, nil, err
		}
		json.Unmarshal([]byte(machineState), &machineStateJSON);
		ips = append(ips, machineStateJSON["PublicIP"].(string))
		urls = append(urls, "https://" + machineStateJSON["PublicIP"].(string))
	}
	return ips, urls, nil
}

func CreateK8SClient(rootCerts ssl.RootCerts, etcdClient etcd.EtcdClient) (*http.Client, error) {
	_, MastersURLs, err := FetchMastersIPs(etcdClient)
	if err != nil {
		return nil, err
	}
	opts := []http.OptionsFunc{
		http.SetServer(MastersURLs[0]),
	}
	ca, _ := rootCerts.Certificate.MarshalPEM()
	cert, pemPrivateKey, _, _ := ssl.CreateAdminCertificate(rootCerts);
	http.SetCA(ca)
	http.SetClientCert(cert)
	http.SetClientKey(pemPrivateKey)
	c, err := http.New(opts...)
	if err != nil {
		log.Print("Unable to create Kubernetes Client", err)
		return nil, err
	}
	return c, nil
}

func RegisterNode(c *http.Client, nodeId string, nodeIp string, nodeOs string, nodeArch string) (*client.Node, error) {
	node, err := c.GetNode(nodeIp)
	if err == nil {
		log.Print("Node already exist");
		return node, nil
	}
	node, err = c.CreateNode(&client.Node{
		Spec: client.NodeSpec{
			ExternalID: nodeId,
			ProviderID: fmt.Sprintf("openstack:///%s", nodeId),
		},
		ObjectMeta: client.ObjectMeta{
			Name: nodeIp,
			Labels: map[string]string{
				"beta.kubernetes.io/arch": nodeArch,
				"beta.kubernetes.io/os": nodeOs,
				"failure-domain.beta.kubernetes.io/region": os.Getenv("OS_REGION_NAME"),
				"kubernetes.io/hostname": nodeIp,
			},
			Annotations: map[string]string{
				"volumes.kubernetes.io/controller-managed-attach-detach": "true",
			},
		},
	})
	if err != nil {
		log.Print("Unable to create node", err)
		return nil, err
	}
	return node, nil
}
