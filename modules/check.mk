USER ?= $(shell whoami)
LIBC_I386 := /lib/ld-linux.so.2
GO_VERSION_MAJOR_MIN := 1
GO_VERSION_MINOR_MIN := 13
GO_VERSION_MIN := $(GO_VERSION_MAJOR_MIN).$(GO_VERSION_MINOR_MIN)
SWTPM_VERSION_MAJOR_MIN := 0
SWTPM_VERSION_MINOR_MIN := 2
SWTPM_VERSION_MIN := $(SWTPM_VERSION_MAJOR_MIN).$(SWTPM_VERSION_MINOR_MIN).0

DEBIAN-OS := $(shell [[ -f /etc/os-release ]] && sed -n "s/^ID.*=\(.*\)$$/\1/p" /etc/os-release |grep -q debian;echo y)
ifeq ($(DEBIAN-OS),y)
HOST-KERNEL := /boot/vmlinuz-$(shell uname -r)
endif

dep_pkgs += wget
check_bins += wget
check_bins += go
dep_pkgs += git
check_bins += git
dep_pkgs += pkg-config
check_bins += pkg-config
dep_pkgs += gcc
check_bins += gcc
### linux
dep_pkgs += flex
check_bins += flex
dep_pkgs += bison
check_bins += bison
dep_pkgs += libelf-dev
check_libs += libelf
### tboot
dep_pkgs += mercurial
check_bins += hg
dep_pkgs += libtspi-dev
check_libs += trousers
check_trousers_header += trousers/tss.h
check_libs += zlib
check_libs += libcrypto
### stboot-installation
dep_pkgs += jq
check_bins += jq
dep_pkgs += e2tools
check_bins += e2mkdir
dep_pkgs += mtools
check_bins += mmd
## syslinux
dep_pkgs += libc6-i386
### debos
## native env
ifeq ($(DEBIAN-OS),y)
dep_pkgs += ubuntu-keyring
dep_pkgs += libglib2.0-dev
check_libs += glib-2.0
check_libs += gobject-2.0
dep_pkgs += libostree-dev
check_libs += ostree-1
dep_pkgs += debootstrap
check_bins += debootstrap
dep_pkgs += systemd-container
check_bins += systemd-nspawn
endif
## docker env
check_bins += docker
## podman env
#check_bins += podman
### qemu test
dep_pkgs += qemu-kvm
# swtpm(https://github.com/stefanberger/swtpm)
dep_pkgs += automake
check_bins += automake
# TODO: check for setuptools python module
dep_pkgs += python3-setuptools
# swtpm deps:
#libtpms(https://github.com/stefanberger/libtpms)
dep_pkgs += autoconf
dep_pkgs += libtool
dep_pkgs += libtasn1-6-dev
dep_pkgs += libgnutls28-dev
dep_pkgs += expect
dep_pkgs += gawk
dep_pkgs += socat
dep_pkgs += python3-pip
dep_pkgs += gnutls-bin
dep_pkgs += libseccomp-dev
# qemu
# TODO: check for ovmf file
dep_pkgs += ovmf

# exit if check is not run explicitly
ifeq ($(findstring check,$(MAKECMDGOALS)),)
CHECK_EXIT := exit 1;
endif

ifeq ($(DEBIAN-OS),y)
install-deps:
	if [ "$(shell id -u)" -ne 0 ]; then \
	  $(call LOG,ERROR,Please run as root); \
	  exit 1; \
	fi;
	$(call LOG,INFO,install dependencies:,$(dep_pkgs))
	apt-get update -yqq
	apt-get install -yqq --no-install-recommends $(dep_pkgs)
	$(eval APT_GO_VERSION := $(shell apt show golang-go 2>/dev/null | \
	  sed -nr 's/^Version: [0-9]:([0-9]+\.[0-9]+).*/\1/p'))
	$(eval APT_GO_VERSION_MAJOR := $(shell echo $(APT_GO_VERSION) | cut -d . -f 1))
	$(eval APT_GO_VERSION_MINOR := $(shell echo $(APT_GO_VERSION) | cut -d . -f 2))
	if ! command -v "go" >/dev/null 2>&1; then \
	  $(call LOG,INFO,check apt Go package version,(>=$(GO_VERSION_MIN))); \
	  $(call LOG,INFO,apt Go package version:,$(APT_GO_VERSION)); \
	  if [ "$(APT_GO_VERSION_MAJOR)" -gt "$(GO_VERSION_MAJOR_MIN)" ] || \
	  ([ "$(APT_GO_VERSION_MAJOR)" -eq "$(GO_VERSION_MAJOR_MIN)" ] && \
	  [ "$(APT_GO_VERSION_MINOR)" -ge "$(GO_VERSION_MINOR_MIN)" ]); then \
	    $(call LOG,PASS,Go version \"$(APT_GO_VERSION)\" supported); \
	    $(call LOG,INFO,install dependencies:,golang-go); \
	    apt-get install -yqq --no-install-recommends golang-go; \
	  else \
	    $(call LOG,WARN,apt Go package version not supported. need manually installation:,go(>=$(GO_VERSION_MIN))); \
	  fi; \
	fi;
	$(call LOG,DONE,dependencies installed)
endif

ifeq ($(IS_ROOT),)

check_targets += $(foreach bin,$(check_bins),check_$(bin)_bin)
check_%_bin:
	@$(call LOG,INFO,check command:,$*)
	if CMD=$$(command -v "$*" 2>/dev/null); then \
	  $(call LOG,PASS,command found:,$${CMD});\
	else \
	  $(call LOG,FAIL,command not found:,$*);\
	  $(CHECK_EXIT) \
	fi;

check_targets += check_go_bin_version
check_go_bin_version: check_go_bin
	$(eval GO_VERSION := $(shell go version 2>/dev/null | sed -nr 's/.*go([0-9]+\.[0-9]+.?[0-9]?).*/\1/p'))
	$(eval GO_VERSION_MAJOR := $(shell echo $(GO_VERSION) | cut -d . -f 1)) \
	$(eval GO_VERSION_MINOR := $(shell echo $(GO_VERSION) | cut -d . -f 2)) \
	if command -v "go" >/dev/null 2>&1; then \
	  $(call LOG,INFO,check Go version,(>=$(GO_VERSION_MIN))); \
	  if [ "$(GO_VERSION_MAJOR)" -gt "$(GO_VERSION_MAJOR_MIN)" ] || \
	  ([ "$(GO_VERSION_MAJOR)" -eq "$(GO_VERSION_MAJOR_MIN)" ] && \
	  [ "$(GO_VERSION_MINOR)" -ge "$(GO_VERSION_MINOR_MIN)" ]); then \
	    $(call LOG,PASS,Go version \"$(GO_VERSION)\" supported); \
	  else \
	    $(call LOG,FAIL,Go version \"$(GO_VERSION)\" is not supported); \
	    $(call LOG,FAIL,Needs version \"$(GO_VERSION_MIN)\" or later.); \
	    $(CHECK_EXIT) \
	  fi; \
	fi;


check_targets += $(foreach lib,$(check_libs),check_$(lib)_lib)
check_%_lib:
	$(call LOG,INFO,check library:,$*)
	if [ -z "$(check_$*_header)" ]; then \
	  if command -v "pkg-config" >/dev/null 2>&1; then \
	    if pkg-config "$*" >/dev/null 2>&1; then \
	      $(call LOG,PASS,library found:,$*);\
	    else \
	      $(call LOG,FAIL,library not found:,$*); \
	      $(CHECK_EXIT) \
	    fi; \
	  else \
	    $(call LOG,FAIL,\"pkg-config\" required to check library:,$*); \
	    $(CHECK_EXIT) \
	  fi; \
	else \
	  $(call LOG,INFO,Lookup \"$*\" library header:,$(check_$*_header)); \
	  if (printf "#include <$(check_$*_header)>\n" | gcc -x c - -Wl,--defsym=main=0 -o /dev/null >/dev/null 2>&1); then \
	    $(call LOG,PASS,library found:,$*); \
	  else \
	    $(call LOG,FAIL,library not found:,$*); \
	    $(CHECK_EXIT) \
	  fi; \
	fi;

check_targets += check_ovmf
check_ovmf:
	found=""; \
	for i in /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd; do \
	  if [ -f "$$i" ]; then \
	    found=y; \
	    $(call LOG,PASS,OVMF binary found:,$$i); \
	  fi; \
	done; \
	if [ "$$found" != "y" ]; then \
	  $(call LOG,FAIL,OVMF binary not found); \
	    $(CHECK_EXIT) \
	fi;

check_targets += check_libc_i386
check_libc_i386:
	@$(call LOG,INFO,check runtime library:,libc(i386)) 
	if [[ ! -f "$(LIBC_I386)" ]];then \
	    $(call LOG,FAIL,runtime library not found:,$(LIBC_I386)); \
	    $(call LOG,FAIL,Install libc runtime library for i368); \
	    $(CHECK_EXIT) \
	else \
	    $(call LOG,PASS,runtime library found:,libc(i386)); \
	fi;

check_targets += check_debos_native

check_debos_native:
	@$(call LOG,INFO,check if OS is debian based)
	if ([[ -f /etc/os-release ]] && sed -n "s/^ID.*=\(.*\)$$/\1/p" /etc/os-release |grep -q debian); then \
	  $(call LOG,PASS,OS is debian based); \
	  $(call LOG,INFO,check if host kernel is readable:,$(HOST-KERNEL)); \
	  if [[ -r "$(HOST-KERNEL)" ]]; then \
	    $(call LOG,INFO,host kernel is readable); \
	    $(call LOG,PASS,native debos build environment is supported.); \
	  else \
	    $(call LOG,FAIL,host kernel \"$(HOST-KERNEL)\" is not readable); \
	    $(call LOG,FAIL,native debos needs a readable kernel to work); \
	    $(call LOG,FAIL,to change the kernel read permission run:,chmod 644 $(HOST-KERNEL)); \
	    $(call LOG,FAIL,native debos build environment is not supported.); \
	    $(CHECK_EXIT) \
	  fi; \
	else \
	  $(call LOG,WARN,OS is not debian based.); \
	  $(call LOG,WARN,native debos build environment is not supported.); \
	  $(CHECK_EXIT) \
	fi;

check_targets += check_debos_docker
check_debos_docker: check_docker_bin
	$(call LOG,INFO,check docker API access); \
	if command -v "docker" >/dev/null 2>&1; then \
	  if docker info >/dev/null 2>&1; then \
	    $(call LOG,PASS,Access to docker API granted. docker debos build environment is supported.); \
	  else \
	    $(call LOG,FAIL,No access to docker API); \
	    $(call LOG,FAIL,start the docker daemon and add user \"$(USER)\" to the docker group); \
	    $(call LOG,FAIL,docker debos build environment is not supported); \
	    $(CHECK_EXIT) \
	  fi; \
	else \
	  $(call LOG,WARN,install docker to enable docker debos build environment.);\
	  $(CHECK_EXIT) \
	fi;

check_targets += check_kvm
check_kvm:
	@$(call LOG,INFO,check for kvm virtualisation accessibility)
	if [[ -c /dev/kvm ]]; then \
	  $(call LOG,PASS,kvm supported (device /dev/kvm available)); \
	else \
	  $(call LOG,FAIL,kvm not supported (device /dev/kvm not available)); \
	  if (cat /proc/cpuinfo |grep -q hypervisor); then \
	    $(call LOG,INFO,hypervisor virtualized environment detected:); \
	    $(call LOG,FAIL,enable nested kvm virtualisation on your host); \
	  else \
	    $(call LOG,INFO,bare-metal environment detected:); \
	    $(call LOG,FAIL,enable virtualisation on your host); \
	  fi; \
	  $(CHECK_EXIT) \
	fi;

check_targets += check_kvm_access
check_kvm_access: check_kvm
	if [[ -c /dev/kvm ]]; then \
	  $(call LOG,INFO,check /dev/kvm device writeability); \
	  if [[ -w /dev/kvm ]]; then \
	    $(call LOG,PASS,/dev/kvm is writable by user \"$(USER)\"); \
	  else \
	    $(call LOG,FAIL,/dev/kvm is not writable by user \"$(USER)\"); \
	    $(call LOG,FAIL,Install \"qemu-kvm\" and add user \"$(USER)\" to the kvm group); \
	    $(CHECK_EXIT) \
	  fi; \
	fi;

check: $(check_targets)

.PHONY: check check_%

endif #ifeq ($(IS_ROOT),)

.PHONY: install-deps
