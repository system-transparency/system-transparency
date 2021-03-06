## debos
debos_bin := $(GOPATH)/bin/debos
# do not edit debos_packages
debos_package := github.com/go-debos/debos
# change debos_repo to use a fork of debos
debos_repo := github.com/system-transparency/debos
debos_src := $(GOPATH)/src/$(debos_package)
# uses the remote defined in debos_repo
debos_branch := system-transparency
## u-root
u-root_bin := $(GOPATH)/bin/u-root
u-root_package := github.com/u-root/u-root
u-root_src := $(GOPATH)/src/$(u-root_package)
u-root_branch := $(patsubst "%",%,$(ST_UROOT_DEV_VERSION))
## stboot
stmanager_bin := $(GOPATH)/bin/stmanager
stboot_package := github.com/system-transparency/stboot
stboot_src := $(GOPATH)/src/$(stboot_package)
stboot_branch := $(patsubst "%",%,$(ST_STBOOT_DEV_VERSION))
## ACM grebber
sinit-acm-grebber_bin := $(GOPATH)/bin/sinit-acm-grebber
sinit-acm-grebber_package := github.com/system-transparency/sinit-acm-grebber
## cpu command for debugging
cpu_bin := $(GOPATH)/bin/cpu
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
	  $(call LOG,INFO,Go|$1: Update,$(1)); \
	else \
	  $(call LOG,INFO,Go|$1: Install,$(1)); \
	fi;
	go build $4 -o $(2).temp $(3)
	if [ -x $(2) ] && diff $(2) $(2).temp >/dev/null; then \
	  $(call LOG,INFO,Go|$1: $(1) already up-to-date); \
	fi
        # use rsync to only update if hash changes (-c flag)
	rsync -c $(2).temp $(2)
	rm $(2).temp
	$(call LOG,DONE,Go|$1:,$$(realpath --relative-to=. $2))
endef


ifeq ($(IS_ROOT),)

go-tools := debos u-root stmanager cpu sinit-acm-grebber
go-tools: $(go-tools)

.PHONY: go-tools $(go-tools)

### debos

debos_get := $(debos_src)/.git/config
debos_remote := $(debos_src)/.git/refs/remotes/system-transparency/system-transparency
debos_fetch := $(debos_src)/.git/FETCH_HEAD
debos_checkout := $(debos_src)/.git/HEAD

$(debos_get):
	@$(call LOG,INFO,Go|debos: Get,$(debos_package))
	go get -d -u $(debos_package)/... 2>/dev/null || \
		rm -rf $(debos_src) && \
		go get -d -u $(debos_package)/...
$(debos_remote): $(debos_get)
	if ! git -C $(debos_src) remote show system-transparency >/dev/null 2>&1; then \
	  $(call LOG,INFO,Go|debos: Add system-transparecy remote,$(debos_repo)); \
	  git -C $(debos_src) remote add system-transparency https://$(debos_repo); \
	fi
$(debos_fetch): $(debos_remote)
	$(call LOG,INFO,Go|debos: Fetch branch,$(debos_branch))
	git -C $(debos_src) fetch --quiet system-transparency $(debos_branch)
$(debos_checkout): $(debos_fetch)
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
	$(call LOG,WARN,Go|debos: Skip checkout (ST_DEVELOP=1))
else
	$(call LOG,INFO,Go|debos: Checkout branch,$(debos_branch))
	git -C $(debos_src) checkout --quiet $(debos_branch)
endif
	touch $@
debos $(debos_bin): $(debos_checkout)
	$(call go_update,debos,$(debos_bin),$(debos_package)/cmd/debos)

ifneq ($(filter $(MAKECMDGOALS),toolchain go-tools debos $(debos_bin)),)
.PHONY: $(debos_fetch)
endif

### u-root

u-root_get := $(u-root_src)/.git/config
u-root_fetch := $(u-root_src)/.git/FETCH_HEAD
u-root_checkout := $(u-root_src)/.git/HEAD

$(u-root_get): $(go_check)
	@$(call LOG,INFO,Go|u-root: Get,$(u-root_package))
	go get -d -u $(u-root_package)
	git -C $(u-root_src) checkout --quiet $(u-root_default_branch)
$(u-root_fetch): $(u-root_get) $(DOTCONFIG)
	@$(call LOG,INFO,Go|u-root: Fetch branch/commit,$(u-root_branch))
	git -C $(u-root_src) fetch --all --quiet
$(u-root_checkout): $(u-root_fetch) $(DOTCONFIG)
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
	$(call LOG,WARN,Go|u-root: Skip checkout (ST_DEVELOP=1))
else
	$(call LOG,INFO,Go|u-root: Checkout branch/commit,$(u-root_branch))
	git -C $(u-root_src) checkout --quiet $(u-root_branch)
endif
	touch $@
u-root $(u-root_bin): $(u-root_checkout)
	$(call go_update,u-root,$(u-root_bin),$(u-root_package))

ifneq ($(filter $(MAKECMDGOALS),toolchain go-tools u-root $(u-root_bin)),)
.PHONY: $(u-root_fetch)
endif

### stboot/stmanager

stboot_get := $(stboot_src)/.git/config
stboot_fetch := $(stboot_src)/.git/FETCH_HEAD
stboot_checkout := $(stboot_src)/.git/HEAD

$(stboot_get): $(go_check)
	@$(call LOG,INFO,Go|stboot: Get,$(stboot_package))
	go get -d -u $(stboot_package)
	git -C $(stboot_src) checkout --quiet $(stboot_default_branch)
$(stboot_fetch): $(stboot_get) $(DOTCONFIG)
	@$(call LOG,INFO,Go|stboot: Fetch branch/commit,$(stboot_branch))
	git -C $(stboot_src) fetch --all --quiet
$(stboot_checkout): $(stboot_fetch) $(DOTCONFIG)
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
	$(call LOG,WARN,Go|stboot: Skip checkout (ST_DEVELOP=1))
else
	$(call LOG,INFO,Go|stboot: Checkout branch/commit,$(stboot_branch))
	git -C $(stboot_src) checkout --quiet $(stboot_branch)
endif
	touch $@
stmanager $(stmanager_bin): $(stboot_checkout)
	$(call go_update,stmanager,$(stmanager_bin),$(stboot_package)/tools/stmanager)

ifneq ($(filter $(MAKECMDGOALS),toolchain go-tools stboot $(stmanager_bin)),)
.PHONY: $(stboot_fetch)
endif

### cpu command

cpu $(cpu_bin) $(cpud_bin):
	@$(call LOG,INFO,Go|cpu: Get,$(cpu_package))
	go get -d -u $(cpu_package)
	$(call go_update,cpu,$(cpu_bin),$(cpu_package))
	$(call go_update,cpud,$(cpud_bin),$(cpud_package))

ifneq ($(filter $(MAKECMDGOALS),toolchain go-tools $(cpu_bin) $(cpud_bin)),)
.PHONY: $(cpu_bin) $(cpud_bin)
endif

### ACM grebber
sinit-acm-grebber $(sinit-acm-grebber_bin):
	@$(call LOG,INFO,Go|sinit-acm-grebber: Get,$(sinit-acm-grebber_package))
	go get -d -u $(sinit-acm-grebber_package)
	$(call go_update,sinit-acm-grebber,$(sinit-acm-grebber_bin),$(sinit-acm-grebber_package))

ifneq ($(filter $(MAKECMDGOALS),toolchain go-tools $(sinit-acm-grebber_bin)),)
.PHONY: $(sinit-acm-grebber_bin)
endif

endif #ifeq ($(IS_ROOT),)
