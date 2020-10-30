# Dockerfile to create a debos image which create reproducible images

FROM ubuntu:focal

# use snapshots to have a specific state of the debian repository
#RUN grep snapshot /etc/apt/sources.list | sed 's/^#//g' > /tmp/sources.list && \
#	mv /tmp/sources.list /etc/apt/ && \
#	echo 'Acquire::Check-Valid-Until "0";' > /etc/apt/apt.conf.d/10no-check-valid-until

# Attempt to fix failing downloads. See https://bugs.launchpad.net/ubuntu/+source/apt/+bug/1801338
RUN printf 'Acquire::http::No-Cache true;\nAcquire::http::Pipeline-Depth "0";\n' > /etc/apt/apt.conf.d/99bugfix_launchpad_issue1801338

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

RUN apt-get -qq update && \
	apt-get -qqy install \
	apt-utils \
	busybox \
	debootstrap \
	fakeroot \
	cpio \
	tar \
	findutils \
	coreutils \
	gzip \
	git \
	golang \
	libc6-dev \
	libostree-dev \
	linux-generic
#	rm -rf /var/lib/apt/lists/*

# use our own debos binary
ARG GOPATH=/usr/local/go
ENV GOPATH=${GOPATH}
RUN go get -d github.com/go-debos/debos/cmd/debos
WORKDIR $GOPATH/src/github.com/go-debos/debos/
RUN git remote add stdebos https://github.com/system-transparency/debos && \
	git fetch stdebos refs/tags/20191115 && git checkout FETCH_HEAD -b 20191115
RUN go install github.com/go-debos/debos/cmd/debos && cp ${GOPATH}/bin/debos /usr/local/bin/debos

# patch debootstrap to support docker builds (only needed for Debian Buster and Ubuntu 20.04 LTS)
COPY debootstrap-buster.patch /tmp/debootstrap-buster.patch
WORKDIR /usr/share/debootstrap/
RUN cat /tmp/debootstrap-buster.patch | patch -p1

WORKDIR /
# use exec form [...] to accepet arguments passed to `docker run`
ENTRYPOINT ["/system-transparency-root/operating-system/ubuntu/docker_entry.sh"]