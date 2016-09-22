FROM quay.io/coreos/hyperkube:v1.3.7_coreos.0

RUN apt-get update && apt-get install -y jq && apt-get clean && rm -rf /var/lib/apt/lists/*
ADD entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
