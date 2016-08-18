GOOS := darwin
GOARCH := amd64
GOPATH := $(shell pwd)
LGOBIN := $(shell pwd)/bin
ENVS := GOOS=$(GOOS) GOARCH=$(GOARCH) GOPATH=$(GOPATH) LGOBIN=$(LGOBIN)
.PHONY: core deploy glide test update_deps

default: core

core:
	$(ENVS) go build -o bin/pidalio github.com/cedbossneo/pidalio

deploy:
	docker build -t cedbossneo/pidalio .

push:
	docker push cedbossneo/pidalio

deps:
	mkdir -p $(GOPATH)/bin
	if [ -f $(LGOBIN)/glide ] ; \
	then \
		echo "Glide already installed" ; \
	else \
		echo "Glide not installed, downloading" ; \
		curl -s -L https://github.com/Masterminds/glide/releases/download/v0.11.1/glide-v0.11.1-$(GOOS)-$(GOARCH).tar.gz | tar -xz --strip=1 && mv ./glide bin/glide ; \
	fi ; \
	cd src/github.com/cedbossneo/pidalio ; \
	$(ENVS) $(LGOBIN)/glide install; \
	cd ../../../..;

update_deps:
	cd src/github.com/cedbossneo/pidalio ; \
	$(ENVS) $(LGOBIN)/glide update; \
	cd ../../../..;

test:
	$(ENVS) go test -v github.com/cedbossneo/pidalio/test/...
