package api

import "github.com/cedbossneo/pidalio/ssl"
import (
	"github.com/gin-gonic/gin"
	"net/http"
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

func CreateAPIServer(rootCerts ssl.RootCerts, serverCerts ssl.ServerCerts, etcdClient etcd.EtcdClient, bindAddress string) {
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
		c.JSON(200, gin.H{
			"cert": string(serverCerts.Certificate),
			"privateKey": string(serverCerts.PrivateKey),
			"publicKey": string(serverCerts.PublicKey),
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
	r.Run(bindAddress)
}
