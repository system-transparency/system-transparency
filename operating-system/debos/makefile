# docker image to build debos image
debos-base-image := ubuntu
debos-base-tag := focal
debos-base := $(debos-base-image):$(debos-base-tag)

# DEBOS_DEBUG=1 adds additional arguments for debugging debos
ifeq ($(DEBOS_DEBUG),1)
  debos-debug-args := --verbose --debug-shell
endif

# docker API access
docker-access := $(shell command -v docker &> /dev/null && docker info >/dev/null 2>&1 && echo y)
# podman is installed
podman-access := $(shell command -v podman &> /dev/null && echo y)
# /dev/kvm exist
kvm-exist := $(shell [[ -e /dev/kvm ]] && echo y)
# /dev/kvm accessable as user
kvm-access := $(shell [[ -w /dev/kvm ]] && echo y)
# debian based disto
debian-os := $(shell [[ -f /etc/os-release ]] && sed -n "s/^ID.*=\(.*\)$$/\1/p" /etc/os-release |grep -q debian;echo y)

## list of available debos environment
#
define DEBOS_ENV_LIST
*** supported environments are:
- native: Run debos on debian based host (user needs kvm access)
- docker: Run debos in a docker container (user needs docker API access and host has kvm avaiable)
- podman: Run debos in a podman container (user needs kvm access)

*** Use DEBOS_ENV=<env>

*** make autodetects available environments, if DEBOS_ENV is not set
endef

# error messages
define DEBOS_ERROR_NO_KVM

*** KVM in not installed on this machine (/dev/kvm is missing)
*** Currently debos only works on host with kvm support
endef

define DEBOS_ERROR_NO_KVM_ACCESS

*** User has no access to kvm.
*** Either add your user to the kvm group or install docker.
endef

define DEBOS_ERROR_NO_ENV

*** No debos environment available to use debos
endef

# TODO: support environment for hosts without kvm
ifneq ($(kvm-exist),y)
DEBOS_ENV := error
  debos-err := $(call DEBOS_ERROR_NO_KVM)
endif

### detect optimal environment
ifeq ($(DEBOS_ENV),)
  # check if user has access to kvm
  ifeq ($(kvm-access),y)
    # detect debian based distros to run debos on host
    ifeq ($(debian-os),y)
    DEBOS_ENV := native
    else
      # detect if podman is installed
      ifeq ($(podman-access),y)
        DEBOS_ENV = podman
      endif
    endif
  endif
endif

ifeq ($(DEBOS_ENV),)
  # use docker if either and of user has kvm access, since it
  # runs as root
  ifeq ($(docker-access),y)
    DEBOS_ENV = docker
  else
    # you need access to either docker API or kvm
    DEBOS_ENV = error
    debos-err := $(call DEBOS_ERROR_NO_KVM_ACCESS))
  endif
  ifeq ($(DEBOS_ENV),)
    DEBOS_ENV = error
    debos-err := $(call DEBOS_ERROR_NO_ENV)
  endif
endif

define DEBOS_ERROR_ENV

$(debos-err)

$(call DEBOS_ENV_LIST)
endef

define DEBOS_UNKNOWN_ENV

Unknown DEBOS_ENV=$(DEBOS_ENV).

$(call DEBOS_ENV_LIST)
endef

# default container arguments
container-args += --rm -it --workdir /recipes -v $(CURDIR)/$$(dir $$<):/recipes -v $(CURDIR)/$(os-out):/out --device /dev/kvm --security-opt label=disable

ifeq ($(DEBOS_ENV),error)
debos-error := $(call DEBOS_ERROR_ENV)
else
  ifeq ($(DEBOS_ENV),native)
    CONTAINER :=
    run-debos := $(debos_bin)
    debos-dep += kvm-check $(debos_bin)
  else
    ifeq ($(DEBOS_ENV),docker)
      CONTAINER := docker
      # check docker API access
      debos-dep += docker-check
      container-dep += docker-check
      # drop priviledge to have user id and access to kvm
      container-args += --user $(shell id -u):$(shell stat -c %g /dev/kvm)
    else
      ifeq ($(DEBOS_ENV),podman)
        CONTAINER := podman
        debos-dep += kvm-check podman-check
        container-dep += kvm-check podman-check
      endif
    endif
    ifneq ($(CONTAINER),)
      # build container image
      run-debos := $(CONTAINER) run $(container-args) debos-$(debos-base)
      debos-dep += setup-debos-$(CONTAINER)
    else
      # unknown environment
      debos-error := $(call DEBOS_UNKNOWN_ENV))
    endif
  endif
endif

# check docker API access
docker-check:
	@echo "[debos] Check docker API access"
ifneq ($(docker-access),y)
	@echo "[debos] Error: no access to docker API"
	@exit 1
endif
	echo "[debos] docker API access granted"

podman-check:
	@echo "[debos] Check podman access"
ifneq ($(podman-access),y)
	@echo "[debos] Error: podman not installed"
	@exit 1
endif
	echo "[debos] docker API access granted"

# check kvm access
kvm-check:
	@echo [debos] Check kvm access
ifneq ($(kvm-access),y)
	@echo "[debos] Error: no access to /dev/kvm"
	@exit 1
endif
	echo "[debos] kvm access granted"

debos-error:
ifneq ($(debos-error),)
	$(error $(debos-error))
endif

# build container image
setup-debos-%: debos-error $(container-dep)
	@echo '[debos] Build $* image debos-$(debos-base)';
	$* build --build-arg="BASE_IMAGE=$(debos-base-image)" --build-arg="BASE_TAG=$(debos-base-tag)" \
		--build-arg="DEBOS_REPO=$(debos_package)" --build-arg="DEBOS_BRANCH=$(debos_branch)" \
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
$1 $3 $4: $2 debos-error $(debos-dep) $(tboot) acm
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
.PHONY: $1
endef

debian_kernel := $(os-out)/debian-buster-amd64.vmlinuz
debian_initramfs := $(os-out)/debian-buster-amd64.cpio.gz
debian_recipe := $(os)/debos/debian.yaml
ubuntu-18_kernel := $(os-out)/ubuntu-bionic-amd64.vmlinuz
ubuntu-18_initramfs := $(os-out)/ubuntu-bionic-amd64.cpio.gz
ubuntu-20_kernel := $(os-out)/ubuntu-focal-amd64.vmlinuz
ubuntu-20_initramfs := $(os-out)/ubuntu-focal-amd64.cpio.gz
ubuntu_recipe := $(os)/debos/ubuntu.yaml

$(eval $(call DEBOS_TARGET,debian,$(debian_recipe),$(debian_kernel),$(debian_initramfs)))
$(eval $(call DEBOS_TARGET,ubuntu-18,$(ubuntu_recipe),$(ubuntu-18_kernel),$(ubuntu-18_initramfs),bionic))
$(eval $(call DEBOS_TARGET,ubuntu-20,$(ubuntu_recipe),$(ubuntu-20_kernel),$(ubuntu-20_initramfs),focal))

.PHONY: debos-error
