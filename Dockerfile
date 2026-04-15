FROM golang:1.25.9-alpine3.23@sha256:30e1078ea1ce91dcd8f48f27c0d7549cf23b32019de8b78cc0dc7b7707987dd5 AS build

RUN apk upgrade --no-cache

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

FROM alpine:3.23.4@sha256:4d889c14e7d5a73929ab00be2ef8ff22437e7cbc545931e52554a7b00e123d8b
LABEL maintainer="github.com/subspacecommunity/subspace"

COPY --from=build  /src/subspace /usr/bin/subspace
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bin/my_init /sbin/my_init

ENV DEBIAN_FRONTEND=noninteractive

RUN chmod +x /usr/bin/subspace /usr/local/bin/entrypoint.sh /sbin/my_init

RUN apk upgrade --no-cache

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
