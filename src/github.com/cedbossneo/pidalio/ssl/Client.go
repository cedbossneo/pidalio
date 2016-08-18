package ssl

import (
	"github.com/spacemonkeygo/openssl"
	"log"
	"github.com/cedbossneo/pidalio/etcd"
	"time"
	"math/big"
	"fmt"
	"github.com/cedbossneo/pidalio/utils"
)

type RootCerts struct {
	Certificate *openssl.Certificate
	privateKey openssl.PrivateKey
	Token string
}

func GenerateKeypairs(bytes int) (openssl.PrivateKey, []byte, []byte){
	key, err := openssl.GenerateRSAKey(bytes)
	if err != nil {
		log.Fatal("Error while generating private key", err)
	}
	pemPrivateKey, err := key.MarshalPKCS1PrivateKeyPEM()
	if err != nil {
		log.Fatal("Error while exporting private key to PEM", err)
	}
	pemPublicKey, err := key.MarshalPKIXPublicKeyPEM()
	if err != nil {
		log.Fatal("Error while exporting public key to PEM", err)
	}
	return key, pemPrivateKey, pemPublicKey
}

func CreateRootKeys(etcd etcd.EtcdClient, token string) (openssl.PrivateKey) {
	key, pemPrivateKey, pemPublicKey := GenerateKeypairs(2048)
	encryptedKey, err := utils.Encrypt(token, pemPrivateKey)
	if err != nil {
		log.Fatal("Error while encrypting Root Private Key", err)
	}
	encryptedPublicKey, err := utils.Encrypt(token, pemPublicKey)
	if err != nil {
		log.Fatal("Error while encrypting Root Public Key", err)
	}
	etcd.CreateKey("/certs/root/key", string(encryptedKey))
	etcd.CreateKey("/certs/root/key.pub", string(encryptedPublicKey))
	return key
}

func CreateRootCertificate(etcd etcd.EtcdClient, token string, key openssl.PrivateKey) *openssl.Certificate {
	certificate, err := openssl.NewCertificate(&openssl.CertificateInfo{
		CommonName: "kube-ca",
		Country: "FR",
		Expires: time.Hour * 24 * 10000,
		Issued: 0,
		Organization: "Kubernetes",
		Serial: big.NewInt(int64(1)),
	}, key)
	if err != nil {
		log.Fatal("Error while creating Root CA", err)
	}
	certificate.Sign(key, openssl.EVP_SHA256)
	cert, err := certificate.MarshalPEM()
	if err != nil {
		log.Fatal("Error while creating Root CA", err)
	}
	encryptedCert, err := utils.Encrypt(token, cert)
	if err != nil {
		log.Fatal("Error while encrypting Root CA", err)
	}
	etcd.CreateKey("/certs/root/cert", string(encryptedCert))
	return certificate
}

func CreateServerCertificate(rootCerts RootCerts, additionalAltNames []string) ([]byte, []byte, []byte, error) {
	key, pemPrivateKey, pemPublicKey := GenerateKeypairs(2048)
	certificate, err := openssl.NewCertificate(&openssl.CertificateInfo{
		CommonName: "kube-apiserver",
		Country: "FR",
		Expires: time.Hour * 24 * 365,
		Issued: 0,
		Organization: "Kubernetes",
		Serial: big.NewInt(int64(1)),
	}, key)
	if err != nil {
		log.Print("Error while creating Server CA", err)
		return nil, nil, nil, err
	}
	certificate.AddExtension(openssl.NID_key_usage, "nonRepudiation,digitalSignature,keyEncipherment")
	certificate.AddExtension(openssl.NID_basic_constraints, "CA:FALSE")
	certificate.AddExtension(openssl.NID_subject_alt_name, "DNS:kubernetes")
	certificate.AddExtension(openssl.NID_subject_alt_name, "DNS:kubernetes.default")
	certificate.AddExtension(openssl.NID_subject_alt_name, "DNS:kubernetes.default.svc")
	certificate.AddExtension(openssl.NID_subject_alt_name, "DNS:kubernetes.default.svc.cluster.local")
	certificate.AddExtension(openssl.NID_subject_alt_name, "IP:10.0.2.1")
	certificate.AddExtension(openssl.NID_subject_alt_name, "IP:10.0.1.3")
	for i := 0; i < len(additionalAltNames); i++ {
		certificate.AddExtension(openssl.NID_subject_alt_name, additionalAltNames[i])
	}
	certificate.SetIssuer(rootCerts.Certificate)
	certificate.Sign(rootCerts.privateKey, openssl.EVP_SHA256)
	cert, err := certificate.MarshalPEM()
	if err != nil {
		log.Print("Error while creating Server CA", err)
		return nil, nil, nil, err
	}
	return cert, pemPrivateKey, pemPublicKey, nil
}

func CreateAdminCertificate(rootCerts RootCerts) ([]byte, []byte, []byte, error) {
	key, pemPrivateKey, pemPublicKey := GenerateKeypairs(2048)
	certificate, err := openssl.NewCertificate(&openssl.CertificateInfo{
		CommonName: "kube-admin",
		Country: "FR",
		Expires: time.Hour * 24 * 365,
		Issued: 0,
		Organization: "Kubernetes",
		Serial: big.NewInt(int64(1)),
	}, key)
	if err != nil {
		log.Print("Error while creating Admin CA", err)
		return nil, nil, nil, err
	}
	certificate.SetIssuer(rootCerts.Certificate)
	certificate.Sign(rootCerts.privateKey, openssl.EVP_SHA256)
	cert, err := certificate.MarshalPEM()
	if err != nil {
		log.Print("Error while creating Admin CA", err)
		return nil, nil, nil, err
	}
	return cert, pemPrivateKey, pemPublicKey, nil
}

func CreateNodeCertificate(rootCerts RootCerts, fqdn string, ip string) ([]byte, []byte, []byte, error) {
	key, pemPrivateKey, pemPublicKey := GenerateKeypairs(2048)
	certificate, err := openssl.NewCertificate(&openssl.CertificateInfo{
		CommonName: fqdn,
		Country: "FR",
		Expires: time.Hour * 24 * 365,
		Issued: 0,
		Organization: "Kubernetes",
		Serial: big.NewInt(int64(1)),
	}, key)
	if err != nil {
		log.Print("Error while creating Node CA", err)
		return nil, nil, nil, err
	}
	certificate.AddExtension(openssl.NID_key_usage, "nonRepudiation,digitalSignature,keyEncipherment")
	certificate.AddExtension(openssl.NID_basic_constraints, "CA:FALSE")
	certificate.AddExtension(openssl.NID_subject_alt_name, fmt.Sprintf("IP:%s", ip))
	certificate.SetIssuer(rootCerts.Certificate)
	certificate.Sign(rootCerts.privateKey, openssl.EVP_SHA256)
	cert, err := certificate.MarshalPEM()
	if err != nil {
		log.Print("Error while creating Node CA", err)
		return nil, nil, nil, err
	}
	return cert, pemPrivateKey, pemPublicKey, nil
}

func LoadRootCerts(etcd etcd.EtcdClient, token string) RootCerts {
	if etcd.KeyExist("/certs/root/key") {
		decryptedKey, err := utils.Decrypt(token, []byte(etcd.GetKey("/certs/root/key")))
		if err != nil {
			log.Fatal("Error while decrypting Root Private Key", err)
		}
		key, err := openssl.LoadPrivateKeyFromPEM(decryptedKey)
		if err != nil {
			log.Fatal("Error while loading Root Private Key", err)
		}
		decryptedCert, err := utils.Decrypt(token, []byte(etcd.GetKey("/certs/root/cert")))
		if err != nil {
			log.Fatal("Error while decrypting Root Certificate", err)
		}
		cert, err := openssl.LoadCertificateFromPEM(decryptedCert)
		if err != nil {
			log.Fatal("Error while loading Root Certificate", err)
		}
		return RootCerts{
			Certificate: cert,
			privateKey: key,
		}
	} else {
		key := CreateRootKeys(etcd, token)
		cert := CreateRootCertificate(etcd, token, key)
		return RootCerts{
			Certificate: cert,
			privateKey: key,
			Token: token,
		}
	}
}
