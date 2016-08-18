package api

import "github.com/cedbossneo/pidalio/ssl"
import (
	"github.com/gin-gonic/gin"
	"strings"
	"net/http"
	"github.com/cedbossneo/pidalio/k8s"
	"errors"
)

func CreateAPIServer(rootCerts ssl.RootCerts) {
	r := gin.Default()
	r.Use(func(c *gin.Context) {
		if c.Query("token") != rootCerts.Token {
			c.AbortWithStatus(http.StatusForbidden)
		} else {
			c.Next()
		}
	})
	r.GET("/certs/ca", func(c *gin.Context) {
		cert, err := rootCerts.Certificate.MarshalPEM();
		if err != nil {
			c.AbortWithError(http.StatusInternalServerError, err)
			return
		}
		c.JSON(200, gin.H{
			"cert": string(cert),
		})
	})
	r.GET("/certs/admin", func(c *gin.Context) {
		cert, private, public, err := ssl.CreateAdminCertificate(rootCerts)
		if err != nil {
			c.AbortWithError(http.StatusInternalServerError, err)
			return
		}
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
		if err != nil {
			c.AbortWithError(http.StatusInternalServerError, err)
			return
		}
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
		if err != nil {
			c.AbortWithError(http.StatusInternalServerError, err)
			return
		}
		c.JSON(200, gin.H{
			"cert": string(cert),
			"privateKey": string(private),
			"publicKey": string(public),
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
		newNode, err := k8s.RegisterNode(rootCerts, nodeId, nodeIp, nodeOs, nodeArch)
		if err != nil {
			c.AbortWithError(http.StatusInternalServerError, err)
			return
		}
		c.JSON(200, newNode)
	})
	r.Run(":3000")
}
