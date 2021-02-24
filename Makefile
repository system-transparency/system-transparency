out ?= out
out-dirs += $(out)
cache ?= cache
common := stboot-installation/common
acm-dir := $(cache)/ACMs
scripts := scripts
stboot-installation := stboot-installation

newest-ospkg := .newest-ospkgs.zip
initramfs := $(out)/stboot-installation/initramfs-linuxboot.cpio.gz

# reproducible builds
LANG:=C
LC_ALL:=C
TZ:=UTC0

# use bash (nix/NixOS friendly)
SHELL := /usr/bin/env bash -euo pipefail -c

# setup development environment if ST_DEVELOP=1
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
	# use local GOPATH
	gopath := $(shell source <(go env) && echo $$GOPATH)
endif

# use custom gopath
ifneq ($(ST_GOPATH),)
# have to be an absolute path
ifeq ($(shell [[ $(ST_GOPATH) = /* ]] && echo y),y)
gopath := $(ST_GOPATH)
else
$(error ST_GOPATH have to be an absolute path!)
endif
endif

# default gopath
ifeq ($(gopath),)
gopath := $(CURDIR)/cache/go
endif

# Make is silent per default, but 'make V=1' will show all compiler calls.
Q:=@
ifneq ($(V),1)
ifneq ($(Q),)
.SILENT:
MAKEFLAGS += -s
OUTREDIRECT :=  > /dev/null
endif
endif

# make "grouped targets" are only supported since version 4.3
MAKE_VER_MAYOR := $(word 1,$(subst ., ,$(MAKE_VERSION)))
MAKE_VER_MINOR := $(word 2,$(subst ., ,$(MAKE_VERSION)))
ifeq ($(shell [ $(MAKE_VER_MAYOR) -ge "4" ] && echo y),y)
ifeq ($(shell [ $(MAKE_VER_MINOR) -ge "3" ] && echo y),y)
GROUP_TARGET := &
endif
endif

# HACK: If "grouped targets" are not supported, emulate the same behavior by removing
#       grouped targets from target dependecies.
define GROUP
$(if $(GROUP_TARGET),$(1),$(word 1,$(1)))
endef

# Make uses maximal available job threads by default
MAKEFLAGS += -j$(shell nproc)

BOARD ?= qemu
DOTCONFIG ?= run.config

ifneq ($(strip $(wildcard $(DOTCONFIG))),)
include $(DOTCONFIG)
endif

# error if configfile is required
define NO_DOTCONFIG_ERROR
file run.config missing:

*** Please provide a config file of run "make config BOARD=<target>"
*** to generate the default configuration.

endef

ROOT_CERT := $(patsubst "%",%,$(ST_SIGNING_ROOT))
ifeq ($(strip $(ROOT_CERT)),)
ROOT_CERT := $(out)/keys/signing_keys/root.cert
endif

IDs = 1 2 3
TYPEs = key cert
KEYS_CERTS += $(foreach TYPE,$(TYPEs),$(foreach ID,$(IDs),$(dir $(ROOT_CERT))signing-key-$(ID).$(TYPE)))

# error if sign keys are required
define NO_SIGN_KEY

$@ file missing.

*** Please provide signing keys and certificates or run "make keygen-sign"
*** to generate example keys and certificates.

endef

CPU_KEY_DIR := $(out)/keys/cpu_keys/
CPU_SSH_FILES := cpu_rsa cpu_rsa.pub ssh_host_rsa_key ssh_host_rsa_key.pub
CPU_SSH_KEYS += $(foreach CPU_SSH_FILE,$(CPU_SSH_FILES),$(CPU_KEY_DIR)/$(CPU_SSH_FILE))


## error if OS packages are missing
# args:
# $1 = target
# $2 = full name
define NO_OS

$@ file missing.

*** Run "make $1" to build $2.

endef


### CONFIG_DEP: function for dependency subconfig generation
#
# If a target depends on specific configuration variables, it should be
# rebuild when the variable changes. The function generates a target
# subconfig with the suffix ".config". when it is added as dependecy to
# the concerned target, it will trigger a rebuild as soon as a variable
# changes.
#
# args:
# $1 = target
# $2 = configuration dependency pattern
#
# Usage example:
# target "example_target" depends on the file "additional_file" and the
# variables "ST_EXAMPLE1" and "ST_EXAMPLE2".
#
# $(eval $(call CONFIG_DEP,example_target,ST_EXAMPLE1|ST_EXAMPLE2))
# example_target: %: %.config (additional_file
# 	(target build instructions)

define CONFIG_DEP
$(1).config: $(DOTCONFIG)
	mkdir -p `dirname $$@`
	grep -E "^$2" $(DOTCONFIG) | sort >> $$@.temp
	rsync -c $$@.temp $$@
	rm $$@.temp
endef

all: $(DOTCONFIG) $(ROOT_CERT) mbr-bootloader-installation efi-application-installation

$(DOTCONFIG):
	$(error $(NO_DOTCONFIG_ERROR))

$(ROOT_CERT) $(KEYS_CERTS)$(GROUG_TARGET):
	$(error $(NO_SIGN_KEY))

ifneq ($(strip $(ST_OS_PKG_KERNEL)),)
OS_KERNEL := $(patsubst "%",%,$(ST_OS_PKG_KERNEL))
endif

ifneq ($(strip $(ST_OS_PKG_INITRAMFS)),)
OS_INITRAMFS := $(patsubst "%",%,$(ST_OS_PKG_INITRAMFS))
endif

include modules/go.mk
include modules/linux.mk

include operating-system/makefile

include stboot-installation/common/makefile
include stboot-installation/mbr-bootloader/makefile
include stboot-installation/efi-application/makefile

help:
	@echo
	@echo  '*** system-transparency targets ***'
	@echo  '  Use "make [target] V=1" for extra build debug information'
	@echo  '  config BOARD=<target>        - Generate default configuration (see contrib/boards)'
	@echo  '  check                        - Check for missing dependencies'
	@echo  '*** clean directory'
	@echo  '  clean                        - Remove all build artifacts'
	@echo  '  clean-keys                   - Remove keys'
	@echo  '  clean-os                     - Remove os-packages'
	@echo  '  distclean                    - Remove all build artifacts, cache and config file'
	@echo  '*** key generation'
	@echo  '  keygen                       - Generate all example keys'
	@echo  '  keygen-sign                  - Generate example sign keys'
	@echo  '  keygen-cpu                   - Generate cpu ssh keys for debugging'
	@echo  '*** Build image'
	@echo  '  all                          - Build all installation options'
	@echo  '  mbr-bootloader-installation  - Build MBR bootloader installation option'
	@echo  '  efi-application-installation - Build EFI application installation option'
	@echo  '*** Build kernel'
	@echo  '  kernel                       - Build all kernels'
	@echo  '  mbr-kernel                   - Build MBR bootloader kernel'
	@echo  '  efi-kernel                   - Build EFI application kernel'
	@echo  '  mbr-kernel-%                 - (debug) Run MBR bootloader kernel target'
	@echo  '  efi-kernel-%                 - (debug) Run EFI application kernel target'
	@echo  '  mbr-kernel-updatedefconfig   - (debug) Update MBR bootloader kernel defconfig'
	@echo  '  efi-kernel-updatedefconfig   - (debug) Update EFI application kernel defconfig'
	@echo  '*** Install toolchain'
	@echo  '  toolchain                    - Build/Update toolchain'
	@echo  '  go-tools                     - Build/Update Golang tools'
	@echo  '*** Build Operating Sytem'
	@echo  '  tboot                        - Build tboot'
	@echo  '  debian                       - Build reproducible Debian Buster'
	@echo  '  ubuntu-18                    - Build reproducible Ubuntu Bionic (latest)'
	@echo  '  ubuntu-20                    - Build reproducible Ubuntu Focal'
	@echo  '  sign                         - Sign OS package'
	@echo  '  upload                       - Upload OS package to provisioning server'
	@echo  '*** Run in QEMU'
	@echo  '  run-mbr-bootloader           - Run MBR bootloader'
	@echo  '  run-efi-application          - Run EFI application'

check:
	@echo [stboot] Checking dependencies
	$(scripts)/checks.sh
	@echo [stboot] Done checking dependencies

config:
	if [[ ! -d contrib/boards/$(BOARD) ]]; then \
	  echo '[stboot] Target board "$(BOARD)" not found'; \
	  echo -e '\n  Avaiable examples boards are:'; \
	  for board in `ls contrib/boards/`; do \
	    echo  "  - $$board"; \
	  done; \
	  echo; \
	  exit 1; \
	fi
	echo [stboot] Apply default configuration for $(BOARD)
	if [[ -f $(DOTCONFIG) ]]; then \
	  if diff $(DOTCONFIG) contrib/default.config $(OUTREDIRECT); then \
	    echo [stboot] configuration already up-to-date; \
	  else \
	    echo [stboot] moving old config to $(notdir $(DOTCONFIG)).old; \
	    mv $(DOTCONFIG) $(DOTCONFIG).old; \
	  fi \
	fi
	BOARD=$(BOARD) envsubst < contrib/default.config  > $(DOTCONFIG)

toolchain: go-tools debos

keygen: keygen-sign keygen-cpu

keygen-sign: $(stmanager_bin)
	@echo [stboot] Generate example signing keys
	GOPATH=$(gopath) $(scripts)/make_signing_keys.sh $(OUTREDIRECT)
	@echo [stboot] Done example signing keys

keygen-cpu: $(call GROUP,$(CPU_SSH_KEYS))

$(call GROUP,$(CPU_SSH_KEYS))$(GROUP_TARGET):
	@echo [stboot] Generate example cpu ssh keys
	$(scripts)/make_cpu_keys.sh $(OUTREDIRECT)
	@echo [stboot] Done example cpu ssh keys

sign: $(DOTCONFIG) $(ROOT_CERT) $(KEYS_CERTS) $(call GROUP,$(OS_KERNEL) $(OS_INITRAMFS)) $(stmanager_bin) $(tboot) acm
	@echo [stboot] Sign OS package
	GOPATH=$(gopath) $(scripts)/create_and_sign_os_package.sh $(OUTREDIRECT)
	@echo [stboot] Done sign OS package

upload: $(newest-ospkg)
	@echo [stboot] Upload OS package
	$(scripts)/upload_os_package.sh $<
	@echo [stboot] Done OS package

$(out-dirs):
	mkdir -p $@

clean-keys:
	rm -rf $(out)/keys

clean-os:
	rm -rf $(out)/os-packages

clean:
	rm -rf $(out)

distclean: clean
	rm -rf $(cache)
	rm -f run.config

.PHONY: all help check default toolchain keygen sign-keygen cpu-keygen tboot acm debian ubuntu-18 ubuntu-20 sign upload clean distclean
