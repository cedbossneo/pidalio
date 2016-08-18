package api

import "github.com/cedbossneo/pidalio/ssl"
import (
	"github.com/gin-gonic/gin"
	"strings"
	"net/http"
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
	r.GET("/certs/admin", func(c *gin.Context) {
		cert, private, public := ssl.CreateAdminCertificate(rootCerts)
		c.JSON(200, gin.H{
			"cert": string(cert),
			"privateKey": string(private),
			"publicKey": string(public),
		})
	})
	r.GET("/certs/server", func(c *gin.Context) {
		cert, private, public := ssl.CreateServerCertificate(rootCerts, strings.Split(c.Query("ip"), ","))
		c.JSON(200, gin.H{
			"cert": string(cert),
			"privateKey": string(private),
			"publicKey": string(public),
		})
	})
	r.GET("/certs/node", func(c *gin.Context) {
		cert, private, public := ssl.CreateNodeCertificate(rootCerts, c.Query("fqdn"), c.Query("ip"))
		c.JSON(200, gin.H{
			"cert": string(cert),
			"privateKey": string(private),
			"publicKey": string(public),
		})
	})
	r.Run(":3000")
}
