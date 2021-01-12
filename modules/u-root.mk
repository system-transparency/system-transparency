build ?= $(CURDIR)/build
gopath ?= $(CURDIR)/go 
package := github.com/u-root/u-root
branch ?= stboot

ARCH := amd64

go_version=$(shell go version | sed -nr 's/.*go([0-9]+\.[0-9]+.?[0-9]?).*/\1/p' )
go_version_major=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\1/p')
go_version_minor=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\2/p')

all: build

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
	@echo [u-root] Get $(package)
	GO111MODULE=off GOPATH=$(gopath) go get -u $(package)

checkout: get
	@echo [u-root] Checkout branch "$(branch)"
	git -C $(gopath)/src/$(package) checkout --quiet $(branch)

build: checkout
	@echo [u-root] Build 
	GOPATH=$(gopath) go install $(package)

.PHONY: all build checkout get version
