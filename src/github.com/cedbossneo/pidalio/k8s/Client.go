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
)

func FetchMasterIP(etcdClient etcd.EtcdClient, unit string) (string, error){
	var masterStateJSON map[string]interface{}
	var machineStateJSON map[string]interface{}
	masterState, err  := etcdClient.GetKey("/_coreos.com/fleet/state/" + unit)
	if err != nil {
		return "", err
	}
	json.Unmarshal([]byte(masterState), &masterStateJSON);
	masterMachineID := masterStateJSON["machineState"].(map[string]interface{})["ID"].(string)
	machineState, err := etcdClient.GetKey("/_coreos.com/fleet/machines/"+ masterMachineID +"/object")
	json.Unmarshal([]byte(machineState), &machineStateJSON);
	return machineStateJSON["PublicIP"].(string), nil
}

func CreateK8SClient(rootCerts ssl.RootCerts, etcdClient etcd.EtcdClient) (*http.Client, error) {
	MasterIP, err := FetchMasterIP(etcdClient, "pidalio-master@1.service")
	if err != nil {
		MasterIP, err = FetchMasterIP(etcdClient, "pidalio-master@2.service")
		if err != nil {
			return nil, err
		}
	}
	opts := []http.OptionsFunc{
		http.SetServer("http://"+MasterIP+":8080"),
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
