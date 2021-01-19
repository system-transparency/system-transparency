top := $(CURDIR)
out ?= $(top)/out
out-dirs += $(out)
cache ?= $(top)/cache
common := $(top)/stboot-installation/common

gopath ?= $(cache)/go
scripts := $(top)/scripts
os := $(top)/operating-system
stboot-installation := $(top)/stboot-installation

# reproducible builds
LANG:=C
LC_ALL:=C
TZ:=UTC0

# Make is silent per default, but 'make V=1' will show all compiler calls.
Q:=@
ifneq ($(V),1)
ifneq ($(Q),)
.SILENT:
MAKEFLAGS += -s
endif
endif

DOTCONFIG ?= $(top)/run.config
HAVE_DOTCONFIG := $(wildcard $(DOTCONFIG))

ifneq ($(strip $(HAVE_DOTCONFIG)),)
include $(DOTCONFIG)
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

all: mbr_bootloader efi_application

include $(top)/modules/go.mk
include $(top)/modules/debos.mk

include $(top)/stboot-installation/common/makefile
include $(top)/stboot-installation/mbr-bootloader/makefile
include $(top)/stboot-installation/efi-application/makefile

help:
	@echo
	@echo  '*** system-transparency targets ***'
	@echo  '  Use "make [target] V=1" for extra build debug information'
	@echo  '*** Build image'
	@echo  '  all                - Build all image formats'
	@echo  '  mbr_bootloader     - Build MBR boatloader image'
	@echo  '  efi_application    - Build EFI aplication image'
	@echo  '*** Install toolchain'
	@echo  '  go-tools           - Build/Update Golang tools'
	@echo  '  tboot              - Build tboot'
	@echo  '  debos              - Create all docker debos environments'
	@echo  '  debos-debian       - Create docker debos environment for debian'
	@echo  '  debos-ubuntu	     - Create docker debos environment for ubuntu'
	@echo  '*** Build Operating Sytem'
	@echo  '  debian             - Build reproducible Debian Buster'
	@echo  '  ubuntu/ubuntu-18   - Build reproducible Ubuntu Bionic (latest)'
	@echo  '  ubuntu-20          - Build reproducible Ubuntu Focal'
	@echo  '  sign               - Sign OS packages'
	@echo  '  upload             - Upload OS package to provisioning server'
	@echo  '*** Run in QEMU'
	@echo  '  run-mbr            - Run MBR bootloader'
	@echo  '  run-efi            - Run EFI application'
	@echo  '*** MISC'
	@echo  '  default            - Generate default run.config'
	@echo  '  check              - Check for missing dependencies'
	@echo  '  keygen             - Generate example keys and certificates'
	@echo

check:
	@echo Checking dependencies
	$(scripts)/checks.sh

default:
	$(scripts)/make_global_config.sh

toolchain: go-tools debos tboot

keygen:
	@echo Generate example keys and certificates
	$(scripts)/make_keys_and_certs.sh

tboot:
	$(os)/common/build_tboot.sh

debian: debos-debian sinit-acm-grebber
	@echo Build debian
	$(os)/debian/make_debian.sh

ubuntu-18: debos-ubuntu sinit-acm-grebber
	@echo Build ubuntu
	$(os)/ubuntu/make_ubuntu.sh "18"

ubuntu-20: debos-ubuntu sinit-acm-grebber
	@echo Build ubuntu
	$(os)/ubuntu/make_ubuntu.sh "20"

ubuntu: ubuntu-18

ifneq ($(strip $(ST_SIGNING_ROOT)),)
$(patsubst "%",%,$(ST_SIGNING_ROOT)):
	@echo
	@echo Error: $(ST_SIGNING_ROOT) file missing.
	@echo        Please provide keys or run \'make keygen\'
	@echo        to generate example keys and certificates.
	@echo
	@exit 1
endif
sign: $(stmanager)
	@echo Sign OS package
	$(scripts)/create_and_sign_os_package.sh

NEWEST-OSPGK := $(top)/.newest-ospkgs.zip
upload: $(NEWEST-OSPKG)
	$(scripts)/upload_os_package.sh $(NEWEST-OSPGK)

mbr_bootloader: $(mbr_image)

efi_application: $(efi_image)

run-mbr:
	$(scripts)/start_qemu_mbr_bootloader.sh

run-efi:
	$(scripts)/start_qemu_efi_application.sh

$(DOTCONFIG):
	@echo
	@echo Error: run.config file missing.
	@echo        Please provide a config file of run \'make default\'
	@echo        to generate a default config.
	@echo
	@exit 1

$(out-dirs):
	mkdir -p $@

clean:
	rm -rf $(out)
	rm -f run.config

distclean: clean
	rm -rf $(cache)

.PHONY: all help check default toolchain go-tools u-root stmanager cpu sinit-acm-grebber keygen debian ubuntu-18 ubuntu-20 ubuntu sign upload mbr_bootloader efi_application run-mbr run-efi clean distclean
