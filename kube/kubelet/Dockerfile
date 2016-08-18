FROM alpine

RUN apk --no-cache add --update jq curl

ADD http://storage.googleapis.com/kubernetes-release/release/v1.3.5/bin/linux/amd64/kubelet /usr/bin/kubelet

ADD *.sh /run/

ENTRYPOINT ["/run/entrypoint.sh"]
