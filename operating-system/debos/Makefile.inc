# docker image to build debos image
debos-base-image := ubuntu
debos-base-tag := focal-20210119
debos-image := debos:$(debos-base-image)-$(debos-base-tag)

# DEBOS_DEBUG=1 adds additional arguments for debugging debos
ifeq ($(DEBOS_DEBUG),1)
  debos-debug-args := --verbose --debug-shell
  container-args += -it
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
# kernel user readable
host-kernel := /boot/vmlinuz-$(shell uname -r)
kernel-access := $(shell [[ -r $(host-kernel) ]] && echo y)

define \n


endef

## list of available debos environment
#
define DEBOS_ENV_LIST
*** supported environments are:
- native: Run debos on debian based host (user needs kvm access and readable host kernel)
- docker: Run debos in a docker container (user needs docker API access and host has kvm avaiable)
- podman: Run debos in a podman container [experimental] (user needs kvm access)

*** set DEBOS_ENV=<env>

*** make autodetects available environments, if DEBOS_ENV is not set
endef

# error messages
define DEBOS_ERROR_NO_KVM
*** KVM in not installed on this machine (/dev/kvm is missing)
*** Currently debos only works on host with kvm support.
*** debos is necessary to build the operating system.
endef

define DEBOS_ERROR_NO_KVM_ACCESS
*** User has no access to kvm.
*** Either add your user to the kvm group or install docker.
endef

define DEBOS_ERROR_NO_KERNEL_ACCESS
*** Host kernel "$(host-kernel)" is not readable

*** native debos on debian-based systems needs a readable kernel to work.
*** to change the kernel read permission run:

    chmod 644 $(host-kernel)

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
      # detect docker API
      ifeq ($(docker-access),y)
        DEBOS_ENV = docker
      else
        # detect if podman is installed
        ifeq ($(podman-access),y)
          DEBOS_ENV = podman
        endif
      endif
    endif
  else
    # use docker if user has no kvm access, since it runs as root
    ifeq ($(docker-access),y)
      DEBOS_ENV = docker
    else
      # you need access to either docker API or kvm
      DEBOS_ENV = error
      debos-err := $(call DEBOS_ERROR_NO_KVM_ACCESS)
    endif
  endif
endif

# no environment found
ifeq ($(DEBOS_ENV),)
  DEBOS_ENV = error
  debos-err := $(call DEBOS_ERROR_NO_ENV)
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
container-args += --rm --workdir /recipes -v $(CURDIR)/$$(dir $$<):/recipes -v $(CURDIR)/$(op-out):/out --device /dev/kvm --security-opt label=disable

# check docker API access
define DOCKER_CHECK

ifneq ($(docker-access),y)
	@$(call LOG,ERROR,No access to docker API)
	@exit 1
endif
	@$(call LOG,INFO,docker API access granted)

endef

define PODMAN_CHECK

ifneq ($(podman-access),y)
	@$(call LOG,ERROR,podman not installed)
	@exit 1
endif
	@$(call LOG,INFO,podman installed)

endef

# check kvm access
define KVM_CHECK

	@$(call LOG,INFO,Check kvm access)
ifneq ($(kvm-access),y)
	@$(call LOG,ERROR,No access to,/dev/kvm)
	@exit 1
endif
	@$(call LOG,INFO,kvm access granted)

endef

# check if kernel is readable
define KERNEL_CHECK

	@$(call LOG,INFO,Check host kernel readability)
ifneq ($(kernel-access),y)
	@echo -e '$(subst $(\n),\n,$(DEBOS_ERROR_NO_KERNEL_ACCESS))'
	@echo -e '$(subst $(\n),\n,$(DEBOS_ENV_LIST))'
	@exit 1
endif
endef

ifeq ($(DEBOS_ENV),error)
  debos-error := $(call DEBOS_ERROR_ENV)
else
  ifeq ($(DEBOS_ENV),native)
    CONTAINER :=
    run-debos := $(debos_bin)
    debos-dep := $(debos_bin) check_debos_native
    debos-dep += check_debootstrap_bin check_systemd-nspawn_bin
  else
    ifeq ($(DEBOS_ENV),docker)
      CONTAINER := docker
      debos-dep := check_debos_docker check_kvm_access
      container-dep += docker-check
      # drop priviledge to have user id and access to kvm (fallback to user group)
      container-args += --user $(ID):$(shell stat -c %g /dev/kvm 2>/dev/null || stat -c %g $(CURDIR))
    else
      ifeq ($(DEBOS_ENV),podman)
        CONTAINER := podman
        debos-check += $(call KVM_CHECK)
        debos-check += $(call PODMAN_CHECK)
      endif
    endif
    ifneq ($(CONTAINER),)
      # build container image
      run-debos := $(CONTAINER) run $(container-args) $(debos-image)
      ifeq ($(findstring godebos/debos,$(debos-image)),)
        debos-setup += $(call SETUP_DEBOS_CONTAINER,$(CONTAINER))
      endif
    else
      # unknown environment
      debos-error := $(call DEBOS_UNKNOWN_ENV))
    endif
  endif
endif


# evaluate debos-error
ifdef debos-error
define EVAL_DEBOS_ERROR
	  echo -e '$(subst $(\n),\n,$(debos-error))'
	  exit 1
endef
debos-check += $(call EVAL_DEBOS_ERROR)
endif

# build container image
define SETUP_DEBOS_CONTAINER
	@$(call LOG,INFO,Build $1 debos image $(debos-image))
	$1 build --build-arg="BASE_IMAGE=$(debos-base-image)" --build-arg="BASE_TAG=$(debos-base-tag)" \
		--build-arg="DEBOS_REPO=$(debos_repo)" --build-arg="DEBOS_BRANCH=$(debos_branch)" \
		-q -t $(debos-image) $(op)/debos;
	@$(call LOG,DONE,debos $1 image $(debos-image))
endef

SOURCE_DATE_EPOCH := $(shell git log -1 --format=format:%ct)

### DEBOS_TARGET
#
## args
# $1 = target name
# $2 = debos recipe
# $3 = kernel file
# $4 = initramfs file
# $5 = suite (optional)

define DEBOS_TARGET
$1-debos-rootfs := $(op-out)/$1-rootfs
ifeq ($(CONTAINER),)
$1-debos-recipe := $2
$1-debos-out := $(op-out)
else
$1-debos-recipe := $(notdir $2)
$1-debos-out := /out
endif
ifneq ($5,)
$1-debos-suite-arg := --template-var=suite:$5
endif
$(op-out)/$3 $(op-out)/$4: $2 $(debos-dep)
	mkdir -p $$(dir $$@)
ifeq ($(IS_ROOT),y)
	chown $(ID):$(GID) -R $(out)
endif
	$(debos-check)
	$(debos-setup)
	@$(call LOG,INFO,Build OS image $1 using $(DEBOS_ENV) debos)
	# single threaded for reproducibility
	$(run-debos) \
		--cpus=1 \
		--environ-var=LC_ALL:$(LC_ALL) \
		--environ-var=LANG:$(LANG) \
	        --environ-var=TZ:$(TZ) \
		--artifactdir=$$($1-debos-out) \
		--environ-var=SOURCE_DATE_EPOCH:$(SOURCE_DATE_EPOCH) \
		$(debos-debug-args) \
		$$($1-debos-suite-arg) \
		$$($1-debos-recipe)
	@$(call LOG,DONE,$$@)
ifeq ($(IS_ROOT),y)
	chown $(ID):$(GID) $(op-out)/$3 $(op-out)/$4
	rm -rf $(CURDIR)/.debos-*
endif

$1: $(call GROUP,$(op-out)/$3 $(op-out)/$4)

.PHONY: $1
.PRECIOUS: $(op-out)/$3 $(op-out)/$4
endef

debian_kernel := debian-buster-amd64.vmlinuz
debian_initramfs := debian-buster-amd64.cpio.gz
debian_recipe := $(op)/debos/debian.yaml
ubuntu-18_kernel := ubuntu-bionic-amd64.vmlinuz
ubuntu-18_initramfs := ubuntu-bionic-amd64.cpio.gz
ubuntu-20_kernel := ubuntu-focal-amd64.vmlinuz
ubuntu-20_initramfs := ubuntu-focal-amd64.cpio.gz
ubuntu_recipe := $(op)/debos/ubuntu.yaml

$(eval $(call DEBOS_TARGET,debian,$(debian_recipe),$(debian_kernel),$(debian_initramfs)))
$(eval $(call DEBOS_TARGET,ubuntu-18,$(ubuntu_recipe),$(ubuntu-18_kernel),$(ubuntu-18_initramfs),bionic))
$(eval $(call DEBOS_TARGET,ubuntu-20,$(ubuntu_recipe),$(ubuntu-20_kernel),$(ubuntu-20_initramfs),focal))
