# Dockerfile to create a debos image which create reproducible images
# ref: https://github.com/go-debos/debos/blob/master/docker/Dockerfile

# mandatory tag for runner
ARG BASE_IMAGE
ARG BASE_TAG

# debos repo and branch
ARG DEBOS_REPO=github.com/go-debos/debos
ARG DEBOS_BRANCH=master

# Global ARGs shared by all stages
ARG DEBIAN_FRONTEND=noninteractive
ARG GOPATH=/usr/local/go

### first stage - builder ###
FROM debian:buster-slim as builder

ARG DEBIAN_FRONTEND
ARG GOPATH
ENV GOPATH=${GOPATH}
ARG DEBOS_REPO
ARG DEBOS_BRANCH

# install debos build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gcc \
        git \
        golang-go \
        libc6-dev \
        libostree-dev && \
    rm -rf /var/lib/apt/lists/*


# Build debos
#RUN go get -d github.com/go-debos/debos/cmd/debos
#WORKDIR $GOPATH/src/github.com/go-debos/debos/cmd/debos
#RUN go get -t ./...

# use custom debos version
RUN go get -d github.com/go-debos/debos/cmd/debos
WORKDIR $GOPATH/src/github.com/go-debos/debos
RUN git remote add stboot https://${DEBOS_REPO}
RUN git fetch stboot ${DEBOS_BRANCH}
RUN git checkout ${DEBOS_BRANCH}
RUN go install github.com/go-debos/debos/cmd/debos

### second stage - runner ###
FROM ${BASE_IMAGE}:${BASE_TAG} as runner

ARG DEBIAN_FRONTEND
ARG GOPATH

# Set HOME to a writable directory in case something wants to cache things
ENV HOME=/tmp

# debos runtime dependencies
# ca-certificates is required to validate HTTPS certificates when getting debootstrap release file
RUN apt-get update && \
    apt-get install -y  \
        apt-transport-https \
        binfmt-support \
        bmap-tools \
        btrfs-progs \
        busybox \
        bzip2 \
        ca-certificates \
        debootstrap \
        dosfstools \
        e2fsprogs \
        equivs \
        fdisk \
        f2fs-tools \
        gzip \
        pigz \
        libostree-1-1 \
	linux-image-virtual \
        parted \
        pkg-config \
        qemu-system-x86 \
        qemu-user-static \
        systemd \
        systemd-container \
        u-boot-tools \
        unzip \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

# make kernel accessable for fakemachine
RUN chmod 644 /boot/vmlinuz*

COPY --from=builder $GOPATH/bin/debos /usr/local/bin/debos

ENTRYPOINT ["/usr/local/bin/debos"]
