## debos
debos_bin := $(gopath)/bin/debos
# do not edit debos_packages
debos_package := github.com/go-debos/debos
# change debos_repo to use a fork of debos
debos_repo := github.com/system-transparency/debos
debos_src := $(gopath)/src/$(debos_package)
# uses the remote defined in debos_repo
debos_branch := system-transparency
## u-root
u-root_bin := $(gopath)/bin/u-root
stmanager_bin := $(gopath)/bin/stmanager
u-root_package := github.com/u-root/u-root
u-root_src := $(gopath)/src/$(u-root_package)
## ACM grebber
sinit-acm-grebber_bin := $(gopath)/bin/sinit-acm-grebber
sinit-acm-grebber_package := github.com/system-transparency/sinit-acm-grebber
## cpu command for debugging
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
# $4 = "flags"
#
define go_update
	if [ -x $(2) ]; then \
	echo [Go] Update $(1); \
	else \
	echo [Go] Install $(1); \
	fi;
	GOPATH=$(gopath) go build $4 -o $(2).temp $(3)
	if [ -x $(2) ] && diff $(2) $(2).temp >/dev/null; then \
	echo [Go] $(1) already up-to-date; \
	fi
        # use rsync to only update if hash changes (-c flag)
	rsync -c $(2).temp $(2)
	rm $(2).temp
	echo [Go] Done $(1)
endef

u-root_branch := $(patsubst "%",%,$(ST_UROOT_DEV_BRANCH))

go_version=$(shell go version | sed -nr 's/.*go([0-9]+\.[0-9]+.?[0-9]?).*/\1/p' )
go_version_major=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\1/p')
go_version_minor=$(shell echo $(go_version) |  sed -nr 's/^([0-9]+)\.([0-9]+)\.?([0-9]*)$$/\2/p')


# phony target to force update
go-tools: cpu sinit-acm-grebber debos u-root

go_check := $(gopath)/.version

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

### debos

debos_get := $(debos_src)/.unpack
debos_remote := $(debos_src)/.remote
debos_checkout := $(debos_src)/.rev

$(debos_get): $(go_check)
	if [[ -f $@ ]]; then \
	  git -C $(dir $@) checkout --quiet master; \
	fi
	@echo [Go] Get $(debos_package)
	GOPATH=$(gopath) go get -d -u $(debos_package)/...
	touch $@
$(debos_remote): $(debos_get)
	@echo [Go] Add stboot remote $(debos_repo)
	git -C $(dir $@) remote add stboot https://$(debos_repo)
	echo $(debos_repo) > $@.temp
	rsync -c $@.temp $@
	rm $@.temp
# phony target to force update
debos_checkout: $(debos_remote)
	@echo [Go] Fetch branch $(debos_branch)
	git -C $(dir $(debos_get)) fetch --quiet stboot $(debos_branch)
	@echo [Go] Checkout branch $(debos_branch)
	git -C $(dir $(debos_get)) checkout --quiet $(debos_branch)
	git -C $(dir $(debos_get)) rev-parse HEAD > $(debos_checkout).temp
	rsync -c $(debos_checkout).temp $(debos_checkout)
	rm $(debos_checkout).temp
$(debos_checkout): $(debos_remote)
	@echo [Go] Fetch branch $(debos_branch)
	git -C $(dir $(debos_get)) fetch --quiet stboot $(debos_branch)
	@echo [Go] Checkout branch $(debos_branch)
	git -C $(dir $<) checkout --quiet $(debos_branch)
	git -C $(dir $<) rev-parse HEAD > $(debos_checkout).temp
	rsync -c $(debos_checkout).temp $(debos_checkout)
	rm $(debos_checkout).temp
# phony target to force update
debos: debos_checkout
	$(call go_update,debos,$(debos_bin),$(debos_package)/cmd/debos)
$(debos_bin): $(debos_checkout)
	$(call go_update,debos,$(debos_bin),$(debos_package)/cmd/debos)

### u-root/stmanager

u-root_get := $(u-root_src)/.complete
u-root_checkout := $(u-root_src)/.rev

$(u-root_get): $(go_check)
	@echo [Go] Get $(u-root_package)
	GO111MODULE=off GOPATH=$(gopath) go get -d -u $(u-root_package)
	touch $@
u-root_checkout: $(u-root_get)
	git -C $(dir $(u-root_checkout)) fetch --all --quiet
ifneq ($(u-root_branch),)
	@echo [Go] Checkout branch $(u-root_branch)
	git -C $(u-root_src) checkout --quiet $(u-root_branch)
else
	@echo [Go] Skip u-root checkout since ST_UROOT_DEV_BRANCH is not set
endif
	git -C $(u-root_src) rev-parse HEAD > $(u-root_checkout).temp
	rsync -c $(u-root_checkout).temp $(u-root_checkout)
	rm $(u-root_checkout).temp
$(u-root_checkout): $(u-root_get)
	git -C $(dir $@) fetch --all --quiet
	@echo [Go] Checkout branch $(u-root_branch)
	git -C $(u-root_src) checkout --quiet $(u-root_branch)
	git -C $(u-root_src) rev-parse HEAD > $@.temp
	rsync -c $@.temp $@
	rm $(u-root_checkout).temp
# phony target to force update
u-root stmanager: $(DOTCONFIG) u-root_checkout
	$(call go_update,u-root,$(u-root_bin),$(u-root_package))
	$(call go_update,stmanager,$(stmanager_bin),$(u-root_package)/tools/stmanager)
$(u-root_bin) $(stmanager_bin): $(DOTCONFIG) $(u-root_checkout)
	$(call go_update,u-root,$(u-root_bin),$(u-root_package))
	$(call go_update,stmanager,$(stmanager_bin),$(u-root_package)/tools/stmanager)

### cpu command

cpu $(cpu_bin) $(cpud_bin)$(GROUP_TARGET):
	@echo [Go] Get $(cpu_package)
	GO111MODULE=off GOPATH=$(gopath) go get -d -u $(cpu_package)
	$(call go_update,cpu,$(cpu_bin),$(cpu_package))
	$(call go_update,cpud,$(cpud_bin),$(cpud_package))

### ACM grebber

sinit-acm-grebber $(sinit-acm-grebber_bin):
	@echo [Go] Get $(sinit-acm-grebber_package)
	GO111MODULE=off GOPATH=$(gopath) go get -d -u $(sinit-acm-grebber_package)
	$(call go_update,sinit-acm-grebber,$(sinit-acm-grebber_bin),$(sinit-acm-grebber_package))

.PHONY: go-tools debos debos_checkout debos_get u-root stmanager u-root_checkout u-root_get cpu sinit-acm-grebber
