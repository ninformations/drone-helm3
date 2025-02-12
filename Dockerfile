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

ARG AWS_IAM_AUTHENTICATOR_VERSION=1.18.8/2020-09-18
ENV AWS_IAM_AUTHENTICATOR_URL=https://amazon-eks.s3.us-west-2.amazonaws.com/${AWS_IAM_AUTHENTICATOR_VERSION}/bin/linux/${ARCH}/aws-iam-authenticator

WORKDIR /tmp
RUN true \
  && wget -O helm.tgz "$HELM_URL" \
  && tar xvpf helm.tgz linux-${ARCH}/helm \
  && mv linux-${ARCH}/helm /usr/local/bin/helm \
  && wget -O /usr/local/bin/kubectl "$KUBECTL_URL" \
  && chmod +x /usr/local/bin/kubectl \
  && wget -O /usr/local/bin/aws-iam-authenticator "$AWS_IAM_AUTHENTICATOR_URL" \
  && chmod +x /usr/local/bin/aws-iam-authenticator

# ---

FROM busybox:glibc

COPY --from=downloader /usr/local/bin/helm /usr/local/bin/helm
COPY --from=downloader /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=downloader /usr/local/bin/aws-iam-authenticator /usr/local/bin/aws-iam-authenticator

COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /tmp/build/drone-helm3 /usr/local/bin/drone-helm3

RUN mkdir /root/.kube

CMD /usr/local/bin/drone-helm3
