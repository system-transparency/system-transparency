gopath := $(cache)/go
u-root_bin := $(gopath)/bin/u-root
stmanager_bin := $(gopath)/bin/stmanager
u-root_package := github.com/u-root/u-root
u-root_src := $(gopath)/src/$(u-root_package)
sinit-acm-grebber_bin := $(gopath)/bin/sinit-acm-grebber
sinit-acm-grebber_package := github.com/system-transparency/sinit-acm-grebber
cpu_bin := $(gopath)/bin/cpu
cpud_bin := $(cpu_bin)d
cpu_package := github.com/u-root/cpu/cmds/cpu
cpud_package := $(cpu_package)d

# go_update:
# Go update mechanism to only update the target go binary, if its content changes.
# This prevents unnecessary rebuild of targets depending the binary.
# 
# args:
# $1 = "package name"
# $2 = "binary file"
# $3 = "package"
#
define go_update
	if [ -x $(2) ]; then \
	echo [Go] Update $(1); \
	else \
	echo [Go] Install $(1); \
	fi;
	GO111MODULE=off GOPATH=$(gopath) go build -o $(2).temp $(3)
	if [ -x $(2) ] && $$(diff $(2) $(2).temp); then \
	echo [Go] $(1) already up-to-date; \
	fi
        # use rsync to only update if hash changes (-c flag)
	rsync -c $(2).temp $(2)
	rm $(2).temp
	echo [Go] Done $(1)
endef

ifneq ($(strip $(ST_UROOT_DEV_BRANCH)),)
u-root_branch := $(ST_UROOT_DEV_BRANCH)
else
u-root_branch := stboot
endif

go_version=$(shell go version | sed -nr 's/.*go([0-9]+\.[0-9]+.?[0-9]?).*/\1/p' )
go_version_major=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\1/p')
go_version_minor=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\2/p')

# target flag file to prevent rebuild
go_check := $(gopath)/.version
u-root_get := $(u-root_src)/.complete
u-root_checkout := $(u-root_src)/.rev

# phony target to force update
go-tools := u-root stmanager cpu sinit-acm-grebber
go-tools: $(go-tools)

$(go_check):
ifeq ("$(go_version)","")
	@printf "\n[Go] Error: Please install Golang >= 1.9\n\n"
	@exit 1
endif
ifeq ($(shell if [ $(go_version_major) -eq 1 ]; then echo y; fi),y)
ifeq ($(shell if [ $(go_version_minor) -lt 9 ]; then echo y; fi),y)
	printf "[Go] Error: Golang version $(go_version) currently installed.\n\
		Please install Golang version >= 1.9\n\n"
	exit 1
endif
endif
	mkdir -p $$(dirname $@)
	touch $(go_check)

u-root_get $(u-root_get): $(go_check)
	@echo [Go] Get $(u-root_package)
	GO111MODULE=off GOPATH=$(gopath) go get -d -u $(u-root_package)
	touch $(u-root_get)

# phony target to force update
u-root_checkout: u-root_get
	@echo [Go] Checkout branch \"$(u-root_branch)\"
	git -C $(u-root_src) checkout --quiet $(u-root_branch)
	git -C $(u-root_src) rev-parse HEAD > $(u-root_checkout).temp
	rsync -c $(u-root_checkout).temp $(u-root_checkout)
	rm $(u-root_checkout).temp
$(u-root_checkout): $(u-root_get)
	@echo [Go] Checkout branch \"$(u-root_branch)\"
	git -C $(u-root_src) checkout --quiet $(u-root_branch)
	git -C $(u-root_src) rev-parse HEAD > $(u-root_checkout).temp
	rsync -c $(u-root_checkout).temp $(u-root_checkout)
	rm $(u-root_checkout).temp

# phony target to force update
u-root: u-root_checkout
	$(call go_update,u-root,$(u-root_bin),$(u-root_package))
$(u-root_bin): $(u-root_checkout)
	$(call go_update,u-root,$(u-root_bin),$(u-root_package))

# phony target to force update
stmanager: u-root_checkout
	$(call go_update,stmanager,$(stmanager_bin),$(u-root_package)/tools/stmanager)
$(stmanager_bin): $(u-root_checkout)
	$(call go_update,stmanager,$(stmanager_bin),$(u-root_package)/tools/stmanager)

cpu $(cpu_bin) $(cpud_bin) &:
	@echo [Go] Get $(cpu_package)
	GO111MODULE=off GOPATH=$(gopath) go get -d -u $(cpu_package)
	$(call go_update,cpu,$(cpu_bin),$(cpu_package))
	$(call go_update,cpud,$(cpud_bin),$(cpud_package))

sinit-acm-grebber $(sinit-acm-grebber_bin):
	@echo [Go] Get $(sinit-acm-grebber_package)
	GO111MODULE=off GOPATH=$(gopath) go get -d -u $(sinit-acm-grebber_package)
	$(call go_update,sinit-acm-grebber,$(sinit-acm-grebber_bin),$(sinit-acm-grebber_package))

.PHONY: go-tools u-root_checkout u-root_get version u-root stmanager cpu sinit-acm-grebber
