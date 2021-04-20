out ?= out
out-dirs += $(out)
cache ?= cache
common := stboot-installation/common
scripts := scripts
stboot-installation := stboot-installation

newest-ospkg := .newest-ospkg.zip

# export all variables to child processes
.EXPORT_ALL_VARIABLES:

# reproducible builds
LANG:=C
LC_ALL:=C
TZ:=UTC0

# use bash (nix/NixOS friendly)
SHELL := /usr/bin/env bash -euo pipefail -c

# Use PID to stop build process on error
MAKEPID:= $(shell echo $$PPID)

# setup development environment if ST_DEVELOP=1
ifeq ($(patsubst "%",%,$(ST_DEVELOP)),1)
# use local GOPATH
ifeq ($(ST_GOPATH),)
	GOPATH := $(shell source <(go env) && echo $$GOPATH)
endif
endif

# use custom GOPATH
ifneq ($(ST_GOPATH),)
# have to be an absolute path
ifeq ($(shell [[ $(ST_GOPATH) = /* ]] && echo y),y)
GOPATH := $(ST_GOPATH)
else
$(error ST_GOPATH have to be an absolute path!)
endif
else
GOPATH := $(CURDIR)/cache/go
endif
# disable go modules
GO111MODULE := off

## logging color
ifneq ($(TERM),)
# all colors
NORMAL = $(shell tput sgr0 2>/dev/null)
RED = $(shell tput setaf 1 2>/dev/null)
GREEN = $(shell tput setaf 2 2>/dev/null)
YELLOW = $(shell tput setaf 3 2>/dev/null)
BLUE = $(shell tput setaf 4 2>/dev/null)
#MAGENTA = $(shell tput setaf 5 2>/dev/null)
CYAN = $(shell tput setaf 6 2>/dev/null)
# log types
INFO_COLOR = $(BLUE)
DONE_COLOR = $(GREEN)
WARN_COLOR = $(YELLOW)
ERROR_COLOR = $(RED)
FILE_COLOR = $(CYAN)
# check logs
PASS_COLOR = $(GREEN)
FAIL_COLOR = $(RED)
endif

## LOG
#
# args:
# $1 = loglevel
# $2 = message
# $3 = file/path (optional)
#
define LOG
printf '[%s] $2 %s\n' '$($1_COLOR)$1$(NORMAL)' '$(FILE_COLOR)$3$(NORMAL)'
endef

# Make is silent per default, but 'make V=1' will show all compiler calls.
Q:=@
ifneq ($(V),1)
ifneq ($(Q),)
.SILENT:
MAKEFLAGS += -s
OUTREDIRECT :=  > /dev/null
endif
endif

## commented out: Emulate grouped target on all make versions
#
# make "grouped targets" are only supported since version 4.3
#MAKE_VER_MAYOR := $(word 1,$(subst ., ,$(MAKE_VERSION)))
#MAKE_VER_MINOR := $(word 2,$(subst ., ,$(MAKE_VERSION)))
#ifeq ($(shell [ $(MAKE_VER_MAYOR) -ge "4" ] && echo y),y)
#ifeq ($(shell [ $(MAKE_VER_MINOR) -ge "3" ] && echo y),y)
#GROUP_TARGET := &
#endif
#endif

# HACK: Emulate grouped target, to support make version <4.3
define GROUP
$(word 1,$(1))
endef

# Make uses maximal available job threads by default
MAKEFLAGS += -j$(shell nproc)

BOARD ?= qemu
DOTCONFIG ?= .config

ifneq ($(strip $(wildcard $(DOTCONFIG))),)
include $(DOTCONFIG)
endif

EXAMPLE_ROOT_CERT := $(out)/keys/signing_keys/root.cert
ROOT_CERT := $(patsubst "%",%,$(ST_SIGNING_ROOT))
ifeq ($(strip $(ROOT_CERT)),)
ROOT_CERT := $(EXAMPLE_ROOT_CERT)
endif

IDs = 1 2 3
TYPEs = key cert
EXAMPLE_KEYS_CERTS += $(foreach TYPE,$(TYPEs),$(foreach ID,$(IDs),$(dir $(EXAMPLE_ROOT_CERT))signing-key-$(ID).$(TYPE)))
KEYS_CERTS += $(foreach TYPE,$(TYPEs),$(foreach ID,$(IDs),$(dir $(ROOT_CERT))signing-key-$(ID).$(TYPE)))

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
	(grep -E "^($2)" $(DOTCONFIG) || true) | sort >> $$@.temp
	rsync -c $$@.temp $$@
	rm $$@.temp
endef

all: $(DOTCONFIG) $(ROOT_CERT) mbr-bootloader-installation efi-application-installation

$(DOTCONFIG):
	@$(call LOG,ERROR,File missing:,$(DOTCONFIG))
	@echo
	@echo '*** Please provide a config file of run "make config BOARD=<target>"'
	@echo '*** to generate the default configuration.'
	@echo
	@exit 1

ifneq ($(strip $(ST_OS_PKG_KERNEL)),)
OS_KERNEL := $(patsubst "%",%,$(ST_OS_PKG_KERNEL))
endif

ifneq ($(strip $(ST_OS_PKG_INITRAMFS)),)
OS_INITRAMFS := $(patsubst "%",%,$(ST_OS_PKG_INITRAMFS))
endif

include modules/check.mk
include modules/go.mk
include modules/linux.mk

include operating-system/Makefile.inc

include stboot-installation/common/Makefile.inc
include stboot-installation/mbr-bootloader/Makefile.inc
include stboot-installation/efi-application/Makefile.inc

help:
	@echo
	@echo  '*** system-transparency targets ***'
	@echo  '  Use "make [target] V=1" for extra build debug information'
	@echo  '  config BOARD=<target>        - Generate default configuration (see contrib/boards)'
	@echo  '  check                        - Check for missing dependencies'
	@echo  '  install-deps                 - Setup and install apt dependencies (Debian bases OS only)'
	@echo  '  toolchain                    - Build/Update toolchain'
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
	@echo  '  mbr-kernel-<kernel target>   - (debug) Run MBR bootloader kernel target'
	@echo  '  mbr-kernel-menuconfig        - (debug) example: Run MBR bootloader kernel menuconfig'
	@echo  '  efi-kernel-<kernel target>   - (debug) Run EFI application kernel target'
	@echo  '  mbr-kernel-nconfig           - (debug) example: Run MBR bootloader kernel nconfig'
	@echo  '  mbr-kernel-updatedefconfig   - (debug) Update MBR bootloader kernel defconfig'
	@echo  '  efi-kernel-updatedefconfig   - (debug) Update EFI application kernel defconfig'
	@echo  '*** Build Operating Sytem'
	@echo  '  tboot                        - Build tboot'
	@echo  '  debian                       - Build reproducible Debian Buster'
	@echo  '  ubuntu-18                    - Build reproducible Ubuntu Bionic (latest)'
	@echo  '  ubuntu-20                    - Build reproducible Ubuntu Focal'
	@echo  '  example-os-package           - Build and Sign an example OS package'
	@echo  '  upload                       - Upload OS package to provisioning server'
	@echo  '*** Run in QEMU'
	@echo  '  run-mbr-bootloader           - Run MBR bootloader'
	@echo  '  run-efi-application          - Run EFI application'

config:
	if [[ ! -d contrib/boards/$(BOARD) ]]; then \
	  $(call LOG,ERROR,Target board \"$(BOARD)\" not found); \
	  echo -e '\n  Available boards are:'; \
	  for board in `ls contrib/boards/`; do \
	    echo  "  - $$board"; \
	  done; \
	  echo; \
	  exit 1; \
	fi
	@$(call LOG,INFO,Apply default configuration for \"$(BOARD)\")
	if [[ -f $(DOTCONFIG) ]]; then \
	  if diff $(DOTCONFIG) <(BOARD=$(BOARD) envsubst < contrib/default.config) $(OUTREDIRECT); then \
	    $(call LOG,WARN,Configuration already up-to-date); \
	  else \
	    $(call LOG,INFO,Moving old config to,$(notdir $(DOTCONFIG)).old); \
	    mv $(DOTCONFIG) $(DOTCONFIG).old; \
	  fi \
	fi
	BOARD=$(BOARD) envsubst < contrib/default.config  > $(DOTCONFIG)

toolchain: go-tools

keygen: keygen-sign keygen-cpu

keygen-sign $(EXAMPLE_ROOT_CERT) $(EXAMPLE_KEYS_CERTS) &: $(stmanager_bin)
	# WARN if example keys are used to build installation
	if [ "$@" != keygen-sign ]; then \
	  $(call LOG,WARN,Using example signing certs and keys for installation); \
	fi
	$(call LOG,INFO,Generate example signing keys); \
	$(scripts)/make_signing_keys.sh $(OUTREDIRECT)
	@$(call LOG,DONE,Example signing keys in:,$(dir $(ROOT_CERT)))

keygen-cpu $(CPU_SSH_KEYS):
	@$(call LOG,INFO,Generate example cpu ssh keys)
	$(scripts)/make_cpu_keys.sh $(OUTREDIRECT)
	@$(call LOG,DONE,Example cpu ssh keys in:,$(CPU_KEY_DIR))

example-os-package: $(DOTCONFIG) $(stmanager_bin) $(call GROUP,$(ROOT_CERT) $(KEYS_CERTS)) $(call GROUP,$(OS_KERNEL) $(OS_INITRAMFS)) $(patsubst "%",%,$(ST_OS_PKG_TBOOT)) $(patsubst %/,%,$(patsubst "%",%,$(ST_OS_PKG_ACM)))
	@$(call LOG,INFO,Sign OS package)
	$(scripts)/create_and_sign_os_package.sh $(OUTREDIRECT)
	@$(call LOG,DONE,OS package:,$$(ls -tp $(os-out) | grep .zip | grep -v /$ | head -1))

upload: $(newest-ospkg)
	@echo [stboot] Upload OS package
	@$(call LOG,INFO,Upload OS package)
	$(scripts)/upload_os_package.sh $<
	@$(call LOG,DONE,Upload OS package)
	@echo [stboot] Done OS package

$(out-dirs):
	mkdir -p $@

clean-keys:
	@$(call LOG,INFO,Remove:,$(out)/keys)
	rm -rf $(out)/keys

clean-os:
	@$(call LOG,INFO,Remove:,$(out)/os-packages)
	rm -rf $(out)/os-packages

clean:
	@$(call LOG,INFO,Remove:,$(out))
	rm -rf $(out)

distclean: clean
	@$(call LOG,INFO,Remove:,$(cache))
	rm -rf $(cache)
	@$(call LOG,INFO,Remove:,$(DOTCONFIG))
	rm -f $(DOTCONFIG)

.PHONY: all help check default toolchain keygen sign-keygen cpu-keygen tboot acm debian ubuntu-18 ubuntu-20 example-os-package upload clean distclean
