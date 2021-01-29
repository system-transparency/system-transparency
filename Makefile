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

DOTCONFIG ?= $(top)/run.config
HAVE_DOTCONFIG := $(wildcard $(DOTCONFIG))

ifneq ($(strip $(HAVE_DOTCONFIG)),)
include $(DOTCONFIG)
endif

all: mbr-bootloader-installation efi-application-installation

ifneq ($(strip $(ST_SIGNING_ROOT)),)
root_cert := $(patsubst "%",%,$(ST_SIGNING_ROOT))
$(root_cert):
	@echo
	@echo 'Error: $@ file missing.'
	@echo '       Please provide keys or run "make keygen"'
	@echo '       to generate example keys and certificates.'
	@echo
	@exit 1
endif
ifneq ($(strip $(ST_OS_PKG_KERNEL)),)
os_kernel := $(top)/$(patsubst "%",%,$(ST_OS_PKG_KERNEL))
endif
ifneq ($(strip $(ST_OS_PKG_INITRAMFS)),)
os_initramfs := $(top)/$(patsubst "%",%,$(ST_OS_PKG_INITRAMFS))
endif

### CONFIG_DEP: function for dependency subconfig generation
#
# If a target depends on specific configuration variables, it should be
# rebuild when the variable changes. The function generates a target
# subconfig with the suffix ".config". when it is added as dependecy to
# the concerned target, it will trigger a rebuild as soon as a variable
# changes.
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


include $(top)/modules/go.mk
include $(top)/modules/debos.mk

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
	$(os)/common/build_tboot.sh $(OUTREDIRECT)
	@echo [stboot] Done tboot

acm: $(sinit-acm-grebber_bin)
	@echo [stboot] Get ACM
	$(os)/common/get_acms.sh $(OUTREDIRECT)
	@echo [stboot] Done ACM

$(debian_kernel) $(debian_initramfs):
	@echo
	@echo 'Error: $@ file missing.'
	@echo '       Run "make debian"'
	@echo '       to build Debian Buster.'
	@echo
	@exit 1
debian: $(tboot) acm
	@echo [stboot] Build Debian Buster
	$(os)/debian/build_os_artefacts.sh $(OUTREDIRECT)
	@echo [stboot] Done Debian Buster

$(ubuntu-18_kernel) $(ubuntu-18_initramfs):
	@echo
	@echo 'Error: $@ file missing.'
	@echo '       Run "make ubuntu-18"'
	@echo '       to build Ubuntu Bionic (latest).'
	@echo
	@exit 1
ubuntu-18: $(tboot) acm
	@echo '[stboot] Build Ubuntu Bionic (latest)'
	$(os)/ubuntu/build_os_artefacts.sh "18" $(OUTREDIRECT)
	@echo '[stboot] Done Ubuntu Bionic (latest)'

ubuntu-20: $(ubuntu-20_kernel) $(ubuntu-20_initramfs)
	@echo
	@echo 'Error: $@ file missing.'
	@echo '       Run "make ubuntu-20"'
	@echo '       to build Ubuntu Focal.'
	@echo
	@exit 1
$(ubuntu-20_kernel) $(ubuntu-20_initramfs): $(tboot) acm
	@echo [stboot] Build Ubuntu Focal
	$(os)/ubuntu/build_os_artefacts.sh "20" $(OUTREDIRECT)
	@echo [stboot] Done Ubuntu Focal

sign: $(DOTCONFIG) $(root_cert) $(os_kernel) $(os_initramfs) $(stmanager_bin)
	@echo [stboot] Sign OS package
	$(scripts)/create_and_sign_os_package.sh $(OUTREDIRECT)
	@echo [stboot] Done sign OS package

upload: $(newest-ospkg)
	@echo [stboot] Upload OS package
	$(scripts)/upload_os_package.sh $<
	@echo [stboot] Done OS package

$(DOTCONFIG):
	@echo
	@echo 'Error: run.config file missing.'
	@echo '       Please provide a config file of run "make default-config"'
	@echo '       to generate a default config.'
	@echo
	@exit 1

$(out-dirs):
	mkdir -p $@

clean:
	rm -rf $(out)

distclean: clean
	rm -rf $(cache)
	rm -f run.config

.PHONY: all help check default toolchain keygen tboot acm debian ubuntu-18 ubuntu-20 sign upload clean distclean
