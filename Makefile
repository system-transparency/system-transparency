top := $(CURDIR)
out ?= $(top)/out
out-dirs += $(out)
cache ?= $(top)/cache
common := $(top)/stboot-installation/common
gopath ?= $(cache)/go
acm-dir := $(cache)/ACMs
scripts := $(top)/scripts
os := $(top)/operating-system
stboot-installation := $(top)/stboot-installation

tboot := $(out)/tboot/tboot.gz
newest-ospkg := $(top)/.newest-ospkgs.zip
debian_kernel := $(out)/operating-system/debian-buster-amd64.vmlinuz
debian_initramfs := $(out)/operating-system/debian-buster-amd64.cpio.gz
ubuntu-18_kernel := $(out)/operating-system/ubuntu-bionic-amd64.vmlinuz
ubuntu-18_initramfs := $(out)/operating-system/ubuntu-bionic-amd64.cpio.gz
ubuntu-20_kernel := $(out)/operating-system/ubuntu-focal-amd64.vmlinuz
ubuntu-20_initramfs := $(out)/operating-system/ubuntu-focal-amd64.cpio.gz
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
ifeq ($(strip $(ROOTCERT)),)
ROOT_CERT := $(out)/keys/signing_keys/root.cert
endif

IDs = 1 2 3 4 5
TYPEs = key cert
KEYS_CERTS += $(foreach TYPE,$(TYPEs),$(foreach ID,$(IDs),$(dir $(ROOT_CERT))signing-key-$(ID).$(TYPE)))

# error if keys/cert are required
define NO_KEY_CERT

$@ file missing.

*** Please provide keys and certificates and or run "make keygen"
*** to generate example keys and certificates.

endef

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

$(ROOT_CERT) $(KEYS_CERTS):
	$(error $(NO_KEY_CERT))

ifneq ($(strip $(ST_OS_PKG_KERNEL)),)
OS_KERNEL := $(top)/$(patsubst "%",%,$(ST_OS_PKG_KERNEL))
endif

ifneq ($(strip $(ST_OS_PKG_INITRAMFS)),)
OS_INITRAMFS := $(top)/$(patsubst "%",%,$(ST_OS_PKG_INITRAMFS))
endif

include $(top)/modules/go.mk
include $(top)/modules/debos.mk
include $(top)/modules/linux.mk

include $(top)/stboot-installation/common/makefile
include $(top)/stboot-installation/mbr-bootloader/makefile
include $(top)/stboot-installation/efi-application/makefile

help:
	@echo
	@echo  '*** system-transparency targets ***'
	@echo  '  Use "make [target] V=1" for extra build debug information'
	@echo  '  default-config               - Generate default run.config'
	@echo  '  check                        - Check for missing dependencies'
	@echo  '  keygen                       - Generate example keys and certificates'
	@echo  '  clean                        - Remove build artifacts'
	@echo  '  distclean                    - Remove build artifacts, cache and config file'
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
	@echo  '  debos                        - Create all docker debos environments'
	@echo  '  debos-debian                 - Create docker debos environment for debian'
	@echo  '  debos-ubuntu	               - Create docker debos environment for ubuntu'
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

keygen:
	@echo [stboot] Generate example keys and certificates
	$(scripts)/make_keys_and_certs.sh $(OUTREDIRECT)
	@echo [stboot] Done example keys and certificates

tboot $(tboot):
	@echo [stboot] Build tboot
	$(os)/common/build_tboot.sh MAKE=$(MAKE) $(OUTREDIRECT)
	@echo [stboot] Done tboot

acm: $(sinit-acm-grebber_bin)
	@echo [stboot] Get ACM
	$(os)/common/get_acms.sh $(OUTREDIRECT)
	@echo [stboot] Done ACM

$(debian_kernel) $(debian_initramfs):
	$(error $(call NO_OS,debian,Debian Buster))
debian: $(tboot) acm
	@echo [stboot] Build Debian Buster
	$(os)/debian/build_os_artefacts.sh $(OUTREDIRECT)
	@echo [stboot] Done Debian Buster

$(ubuntu-18_kernel) $(ubuntu-18_initramfs):
	$(error $(call NO_OS,ubuntu-18,Ubuntu Bionic (latest)))
ubuntu-18: $(tboot) acm
	@echo '[stboot] Build Ubuntu Bionic (latest)'
	$(os)/ubuntu/build_os_artefacts.sh "18" $(OUTREDIRECT)
	@echo '[stboot] Done Ubuntu Bionic (latest)'

$(ubuntu-20_kernel) $(ubuntu-20_initramfs):
	$(error $(call NO_OS,ubuntu-20,Ubuntu Focal))
ubuntu-20: $(tboot) acm
	@echo [stboot] Build Ubuntu Focal
	$(os)/ubuntu/build_os_artefacts.sh "20" $(OUTREDIRECT)
	@echo [stboot] Done Ubuntu Focal

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

.PHONY: all _all help check default toolchain keygen tboot acm debian ubuntu-18 ubuntu-20 sign upload clean distclean
