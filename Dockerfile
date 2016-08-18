FROM alpine

ADD bin/letseat-api /usr/bin/letseat-api

CMD ["letseat-api"]
