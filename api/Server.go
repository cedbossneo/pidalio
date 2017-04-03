package api

import (
	"errors"
	"github.com/cedbossneo/pidalio/ssl"
	"github.com/pressly/chi"
	"net/http"
)

func mid(rootCerts ssl.RootCerts) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Query().Get("token")[0:16] != rootCerts.Token {
				http.Error(w, http.StatusText(http.StatusForbidden), http.StatusForbidden)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func CreateAPIServer(rootCerts ssl.RootCerts, serverCerts ssl.ServerCerts) (http.Handler, error) {
	r := chi.NewRouter()
	r.Use(mid(rootCerts))

	if cert, err := rootCerts.Certificate.MarshalPEM(); err != nil {
		return nil, err
	}
	resCert := fmt.Sprintf(`{"cert": "%s"}`, cert)
	r.Get("/certs/ca", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(resCert))
	})

	if cert, private, public, err := ssl.CreateAdminCertificate(rootCerts); err != nil {
		return nil, err
	}
	resAdmin := fmt.Sprintf(`{"cert": "%s", "privateKey": "%s", "publicKey": "%s"}`, cert, private, public)
	r.Get("/certs/admin", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(resCert))
	})

	resServer := fmt.Sprintf(`{"cert": "%s", "privateKey": "%s", "publicKey": "%s"}`, serverCerts.Certificate, serverCerts.PrivateKey, serverCerts.PublicKey)
	r.Get("/certs/server", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(resServer))
	})

	r.Get("/certs/node", func(w http.ResponseWriter, r *http.Request) {
		ip := r.URL.Query().Get("ip")
		if ip == "" {
			http.Error(w, "ip not defined", http.StatusBadRequest)
			return
		}

		fqdn := r.URL.Query().Get("fqdn")
		if fqdn == "" {
			http.Error(w, "fqdn not defined", http.StatusBadRequest)
			return
		}

		if cert, private, public, err := ssl.CreateNodeCertificate(rootCerts, fqdn, ip); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		res := fmt.Sprintf(`{"cert": "%s", "privateKey": "%s", "publicKey": "%s"}`, cert, private, public)
		w.Write([]byte(res))
	})
	return r, nil
}
