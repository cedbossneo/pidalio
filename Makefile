GOOS := darwin
GOARCH := amd64
LGOBIN := $(shell pwd)/bin
ENVS := GOOS=$(GOOS) GOARCH=$(GOARCH) GOPATH=$(GOPATH) LGOBIN=$(LGOBIN)
.PHONY: core glide test update_deps docker_build docker_pre docker_deps docker_deploy

default: core

core:
	$(ENVS) go build -o bin/pidalio-$(GOOS)-$(GOARCH)

docker_pre:
	docker build -t pidalio-build -f dockerfiles/build/Dockerfile dockerfiles/build/

docker_deps: docker_pre
	docker run --rm -v "$(PWD)":/go/src/github.com/cedbossneo/pidalio -w /go/src/github.com/cedbossneo/pidalio pidalio-build make GOOS=linux deps

docker_build: docker_deps
	docker run --rm -v "$(PWD)":/go/src/github.com/cedbossneo/pidalio -w /go/src/github.com/cedbossneo/pidalio pidalio-build make GOOS=linux

docker_deploy: docker_build
	cp -f bin/pidalio-linux-amd64 dockerfiles/deploy/
	docker build -t cedbossneo/pidalio:v2 -f dockerfiles/deploy/Dockerfile dockerfiles/deploy/
	docker push cedbossneo/pidalio:v2

deps:
	mkdir -p $(GOPATH)/bin
	if [ -f $(LGOBIN)/glide ] ; \
	then \
		echo "Glide already installed" ; \
	else \
		echo "Glide not installed, downloading" ; \
		curl -s -L https://github.com/Masterminds/glide/releases/download/v0.11.1/glide-v0.11.1-$(GOOS)-$(GOARCH).tar.gz | tar -xz --strip=1 && mv ./glide bin/glide ; \
	fi ; \
	$(ENVS) $(LGOBIN)/glide install;

update_deps:
	$(ENVS) $(LGOBIN)/glide update;

test:
	$(ENVS) go test -v ...
