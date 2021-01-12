build ?= $(CURDIR)/build
gopath ?= $(CURDIR)/go 
u-root_package := github.com/u-root/u-root
acm-grebber_package := github.com/system-transparency/sinit-acm-grebber
cpu_repo := github.com/u-root/cpu
branch ?= stboot

ARCH := amd64

go_version=$(shell go version | sed -nr 's/.*go([0-9]+\.[0-9]+.?[0-9]?).*/\1/p' )
go_version_major=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\1/p')
go_version_minor=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\2/p')

all: u-root stmanager cpu-cmd acm-grebber

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
	@echo [u-root] Get $(u-root_package)
	GO111MODULE=off GOPATH=$(gopath) go get -u $(u-root_package)

checkout: get
	@echo [u-root] Checkout branch "$(branch)"
	git -C $(gopath)/src/$(u-root_package) checkout --quiet $(branch)

u-root: checkout
	@echo [u-root] Install u-root
	GOPATH=$(gopath) go install $(u-root_package)

stmanager: checkout
	@echo [u-root] Install stmanager
	GOPATH=$(gopath) go install $(u-root_package)/tools/stmanager

cpu-cmd:
	@echo [u-root] Get cpu command for debugging
	GO111MODULE=auto GOPATH=$(gopath) go get -u $(cpu_repo)/cmds/cpu{,d}

acm-grebber:
	@echo [u-root] Get ACM grebber
	GO111MODULE=auto GOPATH=$(gopath) go get -u $(acm-grebber_package)

.PHONY: all acm-grebber cpu-cmd u-root checkout get version
