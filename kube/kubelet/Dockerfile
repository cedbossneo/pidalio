FROM alpine

RUN apk --no-cache add --update jq curl bash

ADD http://storage.googleapis.com/kubernetes-release/release/v1.3.5/bin/linux/amd64/kubelet /usr/bin/kubelet

RUN chmod +x /usr/bin/kubelet

ADD *.sh /run/
ADD descriptors /etc/kubernetes/descriptors/
ADD manifests /etc/kubernetes/manifests/

ENTRYPOINT ["/run/entrypoint.sh"]
