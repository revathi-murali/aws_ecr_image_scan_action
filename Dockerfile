FROM alpine:3.10

RUN apk add --update jq

# Necessary packages for installing pip
RUN apk add --update python3 python3-dev && \
  python3 -m ensurepip && \
  rm -r /usr/lib/python*/ensurepip && \
  pip3 install --upgrade pip setuptools

# Install awscli
RUN pip3 install awscli

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
