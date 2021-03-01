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
u-root_default_branch := stboot
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
ifeq ($(u-root_branch),)
u-root_branch := $(u-root_default_branch)
endif

# phony target to force update
go-tools: cpu sinit-acm-grebber debos u-root

### debos

debos_get := $(debos_src)/.git/config
debos_remote := $(debos_src)/.git/refs/remotes/system-transparency/system-transparency
debos_fetch := $(debos_src)/.git/FETCH_HEAD
debos_checkout := $(debos_src)/.git/HEAD

$(debos_get):
	@echo [Go] Get $(debos_package)
	GOPATH=$(gopath) go get -d -u $(debos_package)/...
$(debos_remote): $(debos_get)
	if ! git -C $(debos_src) remote show system-transparency >/dev/null 2>&1; then \
	  echo [Go] Add system-transparecy remote $(debos_repo); \
	  git -C $(debos_src) remote add system-transparency https://$(debos_repo); \
	fi
debos_fetch $(debos_fetch): $(debos_remote)
	@echo [Go] Fetch branch $(debos_branch)
	git -C $(debos_src) fetch --quiet system-transparency $(debos_branch)
debos_checkout: debos_fetch
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
	@echo '[Go] Skip checkout (ST_DEVELOP=1)'
else
	@echo '[Go] Checkout branch $(debos_branch)'
	git -C $(debos_src) checkout --quiet $(debos_branch)
endif
$(debos_checkout): $(debos_fetch)
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
	@echo '[Go] Skip checkout (ST_DEVELOP=1)'
else
	@echo '[Go] Checkout branch $(debos_branch)'
	git -C $(debos_src) checkout --quiet $(debos_branch)
endif
# phony target to force update
debos: debos_checkout
	$(call go_update,debos,$(debos_bin),$(debos_package)/cmd/debos)
$(debos_bin): $(debos_checkout)
	$(call go_update,debos,$(debos_bin),$(debos_package)/cmd/debos)

### u-root/stmanager

u-root_get := $(u-root_src)/.git/config
u-root_fetch := $(u-root_src)/.git/FETCH_HEAD
u-root_checkout := $(u-root_src)/.git/HEAD

$(u-root_get): $(go_check)
	@echo [Go] Get $(u-root_package)
	GOPATH=$(gopath) go get -d -u $(u-root_package)
	git -C $(u-root_src) checkout --quiet $(u-root_default_branch)
	touch $@
u-root_fetch $(u-root_fetch): $(u-root_get)
	@echo [Go] Fetch branch $(u-root_branch)
	git -C $(u-root_src) fetch --all --quiet
u-root_checkout: u-root_fetch
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
	@echo '[Go] Skip checkout (ST_DEVELOP=1)'
else
	@echo '[Go] Checkout branch $(u-root_branch)'
	git -C $(u-root_src) checkout --quiet $(u-root_branch)
endif
$(u-root_checkout): $(u-root_fetch)
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
	@echo '[Go] Skip checkout (ST_DEVELOP=1)'
else
	@echo '[Go] Checkout branch $(u-root_branch)'
	git -C $(u-root_src) checkout --quiet $(u-root_branch)
endif
# phony target to force update
u-root stmanager: u-root_checkout
	$(call go_update,u-root,$(u-root_bin),$(u-root_package))
	$(call go_update,stmanager,$(stmanager_bin),$(u-root_package)/tools/stmanager)
$(u-root_bin) $(stmanager_bin): $(u-root_checkout)
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
