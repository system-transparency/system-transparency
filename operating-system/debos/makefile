# docker image to build debos image
debos-base-image := ubuntu
debos-base-tag := focal
debos-base := $(debos-base-image):$(debos-base-tag)

# DEBOS_DEBUG=1 adds additional arguments for debugging debos
ifeq ($(DEBOS_DEBUG),1)
debos-debug-args := --verbose --debug-shell
endif

#detect optimal environment
ifeq ($(DEBOS_ENV),)
# detect debian based distros to run debos on host
ifneq ($(findstring debian,$(shell [[ -f /etc/os-release ]] && sed -n "s/^ID.*=\(.*\)$$/\1/p" /etc/os-release)),)
DEBOS_ENV := native
else
# detect docker api access
ifeq ($(strip $(shell docker info >/dev/null 2>&1; echo $$?)),0)
DEBOS_ENV := docker
else
DEBOS_ENV := podman
endif
endif
endif

define UNKNOWN_DEBOS_ENV

Unknown DEBOS_ENV=$(DEBOS_ENV).

supported environments are:
* native: Run debos on debian based host (need kvm access)
* docker: Run debos in a docker container (need docker API access)
* podman: Runn debos unpriviledged in a podman container (need kvm access)
endef

# default container arguments
container-args += --rm -it --workdir /recipes -v $$(dir $$<):/recipes -v $(os-out):/out --device /dev/kvm --security-opt label=disable

ifeq ($(DEBOS_ENV),native)
CONTAINER :=
run-debos := $(debos_bin)
setup-debos: $(debos_bin)
debos-deb += kvm-check
else
ifeq ($(DEBOS_ENV),docker)
CONTAINER := docker
# check docker API access
container-check += docker-check
# drop priviledge to have user id and access to kvm
container-args += --user $(shell id -u):$(shell stat -c %g /dev/kvm)
else ifeq ($(DEBOS_ENV),podman)
CONTAINER := podman
debos-deb += kvm-check
else
%:
	$(error $(call UNKNOWN_DEBOS_ENV))
endif
# build container image
setup-debos: setup-debos-$(CONTAINER)
run-debos := $(CONTAINER) run $(container-args) debos-$(debos-base)
endif

# check docker API access
docker-check:
	@echo [debos] Check docker API access
	if !(docker info >/dev/null 2>&1); then \
	  echo "[debos] Error: no access to docker API"; \
	  exit 1; \
	else \
	  echo "[debos] docker API access granted"; \
	fi

# check kvm access
kvm-check:
	@echo [debos] Check kvm access
	if [[ ! -w /dev/kvm ]]; then \
	  echo "[debos] Error: no access to /dev/kvm"; \
	  exit 1; \
	else \
	  echo "[debos] kvm access granted"; \
        fi

# build container image
setup-debos-%: $(container-check)
	@echo '[debos] Build $* image debos-$(debos-base)';
	$* build --build-arg="BASE_IMAGE=$(debos-base-image)" --build-arg="BASE_TAG=$(debos-base-tag)" \
		--build-arg="DEBOS_REPO" --build-arg="DEBOS_BRANCH" \
		-q -t debos-$(debos-base) $(os)/debos;
	@echo '[debos] Done $* image debos-$(debos-base) "$(shell $* images -q debos-$(debos-base))"';

### DEBOS_TARGET
#
## args
# $1 = target name
# $2 = debos recipe
# $3 = kernel file
# $4 = initramfs file
# $5 = suite (optional)

define DEBOS_TARGET
ifeq ($(CONTAINER),)
$1-debos-recipe := $2
$1-debos-out := $(os-out)
else
$1-debos-recipe := $(notdir $2)
$1-debos-out := /out
endif
ifneq ($5,)
$1-debos-suite-arg := --template-var=suite:$5
endif
$1 $3 $4: $2 $(debos-deb) setup-debos $(tboot) acm
	mkdir -p $(os-out)
	@echo '[stboot] Build $1 ($(DEBOS_ENV))'
	$(run-debos) \
		--environ-var=SOURCE_DATE_EPOCH:$(shell git log -1 --format=format:%ct) \
		--environ-var=LC_ALL:$(LC_ALL) \
		--environ-var=LANG:$(LANG) \
	        --environ-var=TZ:$(TZ) \
		--artifactdir=$$($1-debos-out) \
		$(debos-debug-args) \
		$$($1-debos-suite-arg) \
		$$($1-debos-recipe)
	@echo [stboot] Done $1
$1-test: $2 setup-debos $(tboot) acm
	mkdir -p $(os-out)
	@echo '[stboot] Debug $1 ($(DEBOS_ENV))'
	$(CONTAINER) run $(container-args) --entrypoint bash debos-$(debos-base)
	@echo [stboot] Done $1
.PHONY: $1
endef

debian_kernel := $(os-out)/debian-amd64.vmlinuz
debian_initramfs := $(os-out)/debian-amd64.cpio.gz
debian_recipe := $(os)/debos/debian.yaml
ubuntu-18_kernel := $(os-out)/ubuntu-bionic-amd64.vmlinuz
ubuntu-18_initramfs := $(os-out)/ubuntu-bionic-amd64.cpio.gz
ubuntu-20_kernel := $(os-out)/ubuntu-focal-amd64.vmlinuz
ubuntu-20_initramfs := $(os-out)/ubuntu-focal-amd64.cpio.gz
ubuntu_recipe := $(os)/debos/ubuntu.yaml

$(eval $(call DEBOS_TARGET,debian,$(debian_recipe),$(debian_kernel),$(debian_initramfs)))
$(eval $(call DEBOS_TARGET,ubuntu-18,$(ubuntu_recipe),$(ubuntu-18_kernel),$(ubuntu-18_initramfs),bionic))
$(eval $(call DEBOS_TARGET,ubuntu-20,$(ubuntu_recipe),$(ubuntu_kernel-20),$(ubuntu_initramfs-20),focal))
