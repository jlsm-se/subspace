FROM golang:1.25.7-alpine3.23@sha256:724e212d86d79b45b7ace725b44ff3b6c2684bfd3131c43d5d60441de151d98e AS build

RUN apk add --no-cache \
    git \
    make

WORKDIR /src

COPY Makefile ./
# go.mod and go.sum if exists
COPY go.* ./
COPY cmd/ ./cmd
COPY web ./web

ARG BUILD_VERSION=unknown

ENV GODEBUG="netdns=go http2server=0"

RUN make build BUILD_VERSION=${BUILD_VERSION}

FROM alpine:3.23.3@sha256:59855d3dceb3ae53991193bd03301e082b2a7faa56a514b03527ae0ec2ce3a95
LABEL maintainer="github.com/subspacecommunity/subspace"

COPY --from=build  /src/subspace /usr/bin/subspace
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bin/my_init /sbin/my_init

ENV DEBIAN_FRONTEND=noninteractive

RUN chmod +x /usr/bin/subspace /usr/local/bin/entrypoint.sh /sbin/my_init

RUN apk add --no-cache \
    iproute2 \
    iptables \
    ip6tables \
    dnsmasq \
    socat  \
    wireguard-tools \
    runit

ENTRYPOINT ["/usr/local/bin/entrypoint.sh" ]

CMD [ "/sbin/my_init" ]
