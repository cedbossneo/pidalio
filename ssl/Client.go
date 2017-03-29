package ssl

import (
	"github.com/sgallagher/openssl"
	"log"
	"github.com/cedbossneo/pidalio/etcd"
	"time"
	"math/big"
	"github.com/cedbossneo/pidalio/utils"
)

type RootCerts struct {
	Certificate *openssl.Certificate
	privateKey openssl.PrivateKey
	Token string
}

type ServerCerts struct {
	Certificate []byte
	PrivateKey []byte
	PublicKey []byte
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

func CreateServerCertificate(etcd etcd.EtcdClient, token string, domain string, kubernetesServiceIp string, rootCerts RootCerts) ([]byte, []byte, []byte) {
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
		log.Fatal("Error while creating Server CA", err)
	}
	certificate.SetVersion(openssl.X509_V3)
	certificate.AddExtension(openssl.NID_key_usage, "nonRepudiation,digitalSignature,keyEncipherment")
	certificate.AddExtension(openssl.NID_basic_constraints, "CA:FALSE")
	certificate.AddExtension(openssl.NID_subject_alt_name, "DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc." + domain + ", IP:" + kubernetesServiceIp)
	certificate.SetIssuer(rootCerts.Certificate)
	certificate.Sign(rootCerts.privateKey, openssl.EVP_SHA256)
	cert, err := certificate.MarshalPEM()
	if err != nil {
		log.Fatal("Error while marshalling Server CA", err)
	}
	encryptedKey, err := utils.Encrypt(token, pemPrivateKey)
	if err != nil {
		log.Fatal("Error while encrypting Server Private Key", err)
	}
	encryptedPublicKey, err := utils.Encrypt(token, pemPublicKey)
	if err != nil {
		log.Fatal("Error while encrypting Server Public Key", err)
	}
	encryptedCert, err := utils.Encrypt(token, cert)
	if err != nil {
		log.Fatal("Error while encrypting Server CA", err)
	}
	etcd.CreateKey("/certs/server/cert", string(encryptedCert))
	etcd.CreateKey("/certs/server/key", string(encryptedKey))
	etcd.CreateKey("/certs/server/key.pub", string(encryptedPublicKey))
	return cert, pemPrivateKey, pemPublicKey
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
	certificate.SetVersion(openssl.X509_V3)
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
	certificate.SetVersion(openssl.X509_V3)
	certificate.AddExtension(openssl.NID_key_usage, "nonRepudiation,digitalSignature,keyEncipherment")
	certificate.AddExtension(openssl.NID_basic_constraints, "CA:FALSE")
	certificate.AddExtension(openssl.NID_subject_alt_name, "IP:" + ip)
	certificate.SetIssuer(rootCerts.Certificate)
	certificate.Sign(rootCerts.privateKey, openssl.EVP_SHA256)
	cert, err := certificate.MarshalPEM()
	if err != nil {
		log.Print("Error while creating Node CA", err)
		return nil, nil, nil, err
	}
	return cert, pemPrivateKey, pemPublicKey, nil
}

func loadRootCerts(etcd etcd.EtcdClient, token string) RootCerts {
	if etcd.KeyExist("/certs/root/key") {
		rootKey, err := etcd.GetKey("/certs/root/key")
		if err != nil {
			log.Fatal("Error while loading Root Private Key", err)
		}
		decryptedKey, err := utils.Decrypt(token, []byte(rootKey))
		if err != nil {
			log.Fatal("Error while decrypting Root Private Key", err)
		}
		key, err := openssl.LoadPrivateKeyFromPEM(decryptedKey)
		if err != nil {
			log.Fatal("Error while loading Root Private Key", err)
		}
		rootCert, err := etcd.GetKey("/certs/root/cert")
		if err != nil {
			log.Fatal("Error while loading Root Certificate", err)
		}
		decryptedCert, err := utils.Decrypt(token, []byte(rootCert))
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
			Token: token,
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

func loadServerCerts(etcd etcd.EtcdClient, token string, domain string, kubernetesServiceIp string, rootCerts RootCerts) ServerCerts {
	if etcd.KeyExist("/certs/server/key") {
		serverKey, err := etcd.GetKey("/certs/server/key")
		if err != nil {
			log.Fatal("Error while loading Server Private Key", err)
		}
		decryptedKey, err := utils.Decrypt(token, []byte(serverKey))
		if err != nil {
			log.Fatal("Error while decrypting Server Private Key", err)
		}
		publicKey, err := etcd.GetKey("/certs/server/key.pub")
		if err != nil {
			log.Fatal("Error while loading Server Public Key", err)
		}
		decryptedPublicKey, err := utils.Decrypt(token, []byte(publicKey))
		if err != nil {
			log.Fatal("Error while decrypting Server Public Key", err)
		}
		cert, err := etcd.GetKey("/certs/server/cert")
		if err != nil {
			log.Fatal("Error while loading Server Certificate", err)
		}
		decryptedCert, err := utils.Decrypt(token, []byte(cert))
		if err != nil {
			log.Fatal("Error while decrypting Server Certificate", err)
		}
		return ServerCerts{
			Certificate: decryptedCert,
			PrivateKey: decryptedKey,
			PublicKey: decryptedPublicKey,
		}
	} else {
		cert, key, publicKey := CreateServerCertificate(etcd, token, domain, kubernetesServiceIp, rootCerts)
		return ServerCerts{
			Certificate: cert,
			PrivateKey: key,
			PublicKey: publicKey,
		}
	}
}

func LoadCerts(etcd etcd.EtcdClient, token string, domain string, kubernetesServiceIp string) (RootCerts, ServerCerts) {
	rootCerts := loadRootCerts(etcd, token)
	serverCerts := loadServerCerts(etcd, token, domain, kubernetesServiceIp, rootCerts)
	return rootCerts, serverCerts
}
