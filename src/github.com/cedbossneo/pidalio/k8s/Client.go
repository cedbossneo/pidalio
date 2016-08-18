package k8s

import (
	"fmt"
	"os"
	"github.com/YakLabs/k8s-client"
	"github.com/YakLabs/k8s-client/http"
	"log"
	"github.com/cedbossneo/pidalio/ssl"
)

func RegisterNode(rootCerts ssl.RootCerts, nodeId string, nodeIp string, nodeOs string, nodeArch string) (*client.Node, error) {
	opts := []http.OptionsFunc{
		http.SetServer(os.Getenv("K8S_URI")),
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
	node, err := c.GetNode(nodeIp)
	if err != nil {
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