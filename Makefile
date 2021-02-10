top := $(CURDIR)
out ?= $(top)/out
out-dirs += $(out)
cache ?= $(top)/cache
common := $(top)/stboot-installation/common
gopath ?= $(cache)/go
acm-dir := $(cache)/ACMs
scripts := $(top)/scripts
stboot-installation := $(top)/stboot-installation

tboot := $(out)/tboot/tboot.gz
newest-ospkg := $(top)/.newest-ospkgs.zip
initramfs := $(out)/stboot-installation/initramfs-linuxboot.cpio.gz

# reproducible builds
LANG:=C
LC_ALL:=C
TZ:=UTC0

# use bash (nix/NixOS friendly)
SHELL := /usr/bin/env bash -euo pipefail -c

# Make is silent per default, but 'make V=1' will show all compiler calls.
Q:=@
ifneq ($(V),1)
ifneq ($(Q),)
.SILENT:
MAKEFLAGS += -s
OUTREDIRECT :=  > /dev/null
endif
endif

# Make uses maximal available job threads by default
MAKEFLAGS += -j$(shell nproc)

DOTCONFIG ?= $(top)/run.config

ifneq ($(strip $(wildcard $(DOTCONFIG))),)
include $(DOTCONFIG)
endif

# error if configfile is required
define NO_DOTCONFIG_ERROR
file run.config missing:

*** Please provide a config file of run "make default-config"
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

*** Please provide signing keys and certificates or run "make sign-keygen"
*** to generate example keys and certificates.

endef

CPU_KEY_DIR := $(out)/keys/cpu_keys/
CPU_SSH_FILES := cpu_rsa  cpu_rsa.pub  ssh_host_rsa_key  ssh_host_rsa_key.pub
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

$(ROOT_CERT) $(KEYS_CERTS) &:
	$(error $(NO_SIGN_KEY))

ifneq ($(strip $(ST_OS_PKG_KERNEL)),)
OS_KERNEL := $(top)/$(patsubst "%",%,$(ST_OS_PKG_KERNEL))
endif

ifneq ($(strip $(ST_OS_PKG_INITRAMFS)),)
OS_INITRAMFS := $(top)/$(patsubst "%",%,$(ST_OS_PKG_INITRAMFS))
endif

include $(top)/modules/go.mk
include $(top)/modules/linux.mk

include $(top)/operating-system/makefile

include $(top)/stboot-installation/common/makefile
include $(top)/stboot-installation/mbr-bootloader/makefile
include $(top)/stboot-installation/efi-application/makefile

help:
	@echo
	@echo  '*** system-transparency targets ***'
	@echo  '  Use "make [target] V=1" for extra build debug information'
	@echo  '  default-config               - Generate default run.config'
	@echo  '  check                        - Check for missing dependencies'
	@echo  '  clean                        - Remove build artifacts'
	@echo  '  distclean                    - Remove build artifacts, cache and config file'
	@echo  '*** key generation'
	@echo  '  keygen                       - Generate all example keys'
	@echo  '  sign-keygen                  - Generate example sign keys'
	@echo  '  cpu-keygen                   - Generate cpu ssh keys for debugging'
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
	@echo  '  setup-debos                  - Create all docker debos environments'
	@echo  '  setup-debos-debian           - Create docker debos environment for debian'
	@echo  '  setup-debos-ubuntu	       - Create docker debos environment for ubuntu'
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

default-config:
	$(scripts)/make_global_config.sh

toolchain: go-tools debos

keygen: sign-keygen cpu-keygen

sign-keygen: $(stmanager_bin)
	@echo [stboot] Generate example signing keys
	$(scripts)/make_signing_keys.sh $(OUTREDIRECT)
	@echo [stboot] Done example signing keys

cpu-keygen: $(CPU_SSH_KEYS)

$(CPU_SSH_KEYS) &:
	@echo [stboot] Generate example cpu ssh keys
	$(scripts)/make_cpu_keys.sh $(OUTREDIRECT)
	@echo [stboot] Done example cpu ssh keys

sign: $(DOTCONFIG) $(ROOT_CERT) $(KEYS_CERTS) $(OS_KERNEL) $(OS_INITRAMFS) $(stmanager_bin)
	@echo [stboot] Sign OS package
	$(scripts)/create_and_sign_os_package.sh $(OUTREDIRECT)
	@echo [stboot] Done sign OS package

upload: $(newest-ospkg)
	@echo [stboot] Upload OS package
	$(scripts)/upload_os_package.sh $<
	@echo [stboot] Done OS package

$(out-dirs):
	mkdir -p $@

clean:
	rm -rf $(out)

distclean: clean
	rm -rf $(cache)
	rm -f run.config

.PHONY: all help check default toolchain keygen sign-keygen cpu-keygen tboot acm debian ubuntu-18 ubuntu-20 sign upload clean distclean
