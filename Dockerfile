FROM golang:1.14 as builder

ARG ARCH=amd64

WORKDIR /tmp/build
COPY . .
RUN GOOS=linux go build -mod=vendor -ldflags="-s -w"

# ---

FROM alpine as downloader

ARG ARCH=amd64
ARG HELM_VERSION=3.5.0
ENV HELM_URL=https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz

ARG KUBECTL_VERSION=1.19.7
ENV KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl

WORKDIR /tmp
RUN true \
  && wget -O helm.tgz "$HELM_URL" \
  && tar xvpf helm.tgz linux-${ARCH}/helm \
  && mv linux-${ARCH}/helm /usr/local/bin/helm \
  && wget -O /usr/local/bin/kubectl "$KUBECTL_URL" \
  && chmod +x /usr/local/bin/kubectl

# ---

FROM busybox:glibc

COPY --from=downloader /usr/local/bin/helm /usr/local/bin/helm
COPY --from=downloader /usr/local/bin/kubectl /usr/local/bin/kubectl

COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /tmp/build/drone-helm3 /usr/local/bin/drone-helm3

RUN mkdir /root/.kube

CMD /usr/local/bin/drone-helm3
