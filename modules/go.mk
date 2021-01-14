u-root_package := github.com/u-root/u-root
u-root_bin := $(gopath)/bin/u-root
stmanager_bin := $(gopath)/bin/stmanager
sinit-acm-grebber_package := github.com/system-transparency/sinit-acm-grebber
sinit-acm-grebber_bin := $(gopath)/bin/sinit-acm-grebber
cpu_package := github.com/u-root/cpu
cpu_bin := $(gopath)/bin/cpu

ARCH := amd64
UROOT_BRANCH ?= stboot

go_version=$(shell go version | sed -nr 's/.*go([0-9]+\.[0-9]+.?[0-9]?).*/\1/p' )
go_version_major=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\1/p')
go_version_minor=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\2/p')

all: $(u-root_bin) $(stmanager_bin) $(cpu_bin) $(sinit-acm-grebber_bin)

version:
ifeq ("$(go_version)","")
	@printf "\n[u-root] Error: Please install Golang >= 1.9\n\n"
	@exit 1
endif
ifeq ($(shell if [ $(go_version_major) -eq 1 ]; then echo y; fi),y)
ifeq ($(shell if [ $(go_version_minor) -lt 9 ]; then echo y; fi),y)
	printf "[n-root] Error: Golang version $(go_version) currently installed.\n\
		Please install Golang version >= 1.9\n\n"
	exit 1
endif
endif

get: version
	@echo [Go] Get $(u-root_package)
	GO111MODULE=off GOPATH=$(gopath) go get -d -u $(u-root_package)

checkout: get
	@echo [Go] Checkout branch \"$(UROOT_BRANCH)\"
	git -C $(gopath)/src/$(u-root_package) checkout --quiet $(UROOT_BRANCH)

$(u-root_bin): checkout
	@echo [Go] Install u-root
	GOPATH=$(gopath) go install $(u-root_package)

$(stmanager_bin): checkout
	@echo [Go] Install stmanager
	GOPATH=$(gopath) go install $(u-root_package)/tools/stmanager

$(cpu_bin):
	@echo [Go] Install cpu command for debugging
	GO111MODULE=auto GOPATH=$(gopath) go get -u $(cpu_package)/cmds/cpu{,d}

$(sinit-acm-grebber_bin):
	@echo [Go] Install ACM grebber
	GO111MODULE=auto GOPATH=$(gopath) go get -u $(sinit-acm-grebber_package)

.PHONY: all checkout get version
