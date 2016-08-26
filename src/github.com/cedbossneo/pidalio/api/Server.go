package api

import "github.com/cedbossneo/pidalio/ssl"
import (
	"github.com/gin-gonic/gin"
	"strings"
	"net/http"
	"github.com/cedbossneo/pidalio/k8s"
	"errors"
	"github.com/cedbossneo/pidalio/etcd"
)

func checkErrors(c *gin.Context, err error) bool {
	if err != nil {
		c.AbortWithError(http.StatusInternalServerError, err)
		return true
	}
	return false
}

func CreateAPIServer(rootCerts ssl.RootCerts, etcdClient etcd.EtcdClient) {
	r := gin.Default()
	r.Use(func(c *gin.Context) {
		if c.Query("token")[0:16] != rootCerts.Token {
			c.AbortWithStatus(http.StatusForbidden)
		} else {
			c.Next()
		}
	})
	r.GET("/certs/ca", func(c *gin.Context) {
		cert, err := rootCerts.Certificate.MarshalPEM();
		if checkErrors(c, err) { return }
		c.JSON(200, gin.H{
			"cert": string(cert),
		})
	})
	r.GET("/certs/admin", func(c *gin.Context) {
		cert, private, public, err := ssl.CreateAdminCertificate(rootCerts)
		if checkErrors(c, err) { return }
		c.JSON(200, gin.H{
			"cert": string(cert),
			"privateKey": string(private),
			"publicKey": string(public),
		})
	})
	r.GET("/certs/server", func(c *gin.Context) {
		ip, exist := c.GetQuery("ip")
		if !exist {
			c.AbortWithError(http.StatusBadRequest, errors.New("ip not defined"))
			return
		}
		cert, private, public, err := ssl.CreateServerCertificate(rootCerts, strings.Split(ip, ","))
		if checkErrors(c, err) { return }
		c.JSON(200, gin.H{
			"cert": string(cert),
			"privateKey": string(private),
			"publicKey": string(public),
		})
	})
	r.GET("/certs/node", func(c *gin.Context) {
		ip, exist := c.GetQuery("ip")
		if !exist {
			c.AbortWithError(http.StatusBadRequest, errors.New("ip not defined"))
			return
		}
		fqdn, exist := c.GetQuery("fqdn")
		if !exist {
			c.AbortWithError(http.StatusBadRequest, errors.New("fqdn not defined"))
			return
		}
		cert, private, public, err := ssl.CreateNodeCertificate(rootCerts, fqdn, ip)
		if checkErrors(c, err) { return }
		c.JSON(200, gin.H{
			"cert": string(cert),
			"privateKey": string(private),
			"publicKey": string(public),
		})
	})

	r.GET("/k8s/masters", func(c *gin.Context) {
		MasterIP1, err := k8s.FetchMasterIP(etcdClient, "pidalio-master@1.service")
		if checkErrors(c, err) { return }
		MasterIP2, err := k8s.FetchMasterIP(etcdClient, "pidalio-master@2.service")
		if checkErrors(c, err) { return }
		c.JSON(200, gin.H{
			"masters": []string{
				MasterIP1, MasterIP2,
			},
			"urls": []string{
				"https://" + MasterIP1, "https://" + MasterIP2,
			},
		})
	})
	r.POST("/register/node", func(c *gin.Context) {
		nodeIp, exist := c.GetQuery("ip")
		if !exist {
			c.AbortWithError(http.StatusBadRequest, errors.New("ip not defined"))
			return
		}
		nodeId, exist := c.GetQuery("id")
		if !exist {
			c.AbortWithError(http.StatusBadRequest, errors.New("id not defined"))
			return
		}
		nodeArch, exist := c.GetQuery("arch")
		if !exist {
			c.AbortWithError(http.StatusBadRequest, errors.New("arch not defined"))
			return
		}
		nodeOs, exist := c.GetQuery("os")
		if !exist {
			c.AbortWithError(http.StatusBadRequest, errors.New("os not defined"))
			return
		}
		client, err := k8s.CreateK8SClient(rootCerts, etcdClient)
		if checkErrors(c, err) { return }
		newNode, err := k8s.RegisterNode(client, nodeId, nodeIp, nodeOs, nodeArch)
		if checkErrors(c, err) { return }
		c.JSON(200, newNode)
	})
	r.Run(":3000")
}
