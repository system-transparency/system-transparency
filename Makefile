top := $(CURDIR)
out ?= $(top)/out
out-dirs += $(out)
cache ?= $(top)/cache
common := $(top)/stboot-installation/common
gopath ?= $(cache)/go
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

all: mbr-image efi-image

ifneq ($(strip $(ST_SIGNING_ROOT)),)
root_cert := $(patsubst "%",%,$(ST_SIGNING_ROOT))
$(root_cert):
	@echo
	@echo Error: $@ file missing.
	@echo        Please provide keys or run \'make keygen\'
	@echo        to generate example keys and certificates.
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
	@echo  '*** Build image'
	@echo  '  all                - Build all image formats'
	@echo  '  mbr-image          - Build MBR boatloader image'
	@echo  '  efi-image          - Build EFI application image'
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
	@echo  '  mbr-run            - Run MBR bootloader'
	@echo  '  efi-run            - Run EFI application'
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
	$(scripts)/make_keys_and_certs.sh $(OUTREDIRECT)
	@echo Done example keys and certificates

tboot $(tboot):
	@echo Build tboot
	$(os)/common/build_tboot.sh
	@echo Done tboot

debian $(debian_kernel) $(debian_initramfs): debos-debian $(sinit-acm-grebber_bin)
	@echo Build Debian Buster
	$(os)/debian/make_debian.sh
	@echo Done Debian Buster

ubuntu-18 $(ubuntu-18_kernel) $(ubunut-18_initramfs): debos-ubuntu $(sinit-acm-grebber_bin)
	@echo 'Build Ubuntu Bionic (latest)'
	$(os)/ubuntu/make_ubuntu.sh "18"
	@echo Done Ubuntu Bionic (latest)

ubuntu-20 $(ubuntu-20_kernel) $(ubunut-20_initramfs): debos-ubuntu $(sinit-acm-grebber_bin)
	@echo Build Ubuntu Focal
	$(os)/ubuntu/make_ubuntu.sh "20"
	@echo Done Ubuntu Focal

ubuntu: ubuntu-18

sign: $(stmanager_bin) $(os_kernel) $(os_initramfs)
	@echo Sign OS package
	$(scripts)/create_and_sign_os_package.sh
	@echo Done sign OS package

upload: $(newest-ospkg)
	@echo Upload OS package
	$(scripts)/upload_os_package.sh $<
	@echo Done OS package

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

.PHONY: all help check default toolchain keygen debian ubuntu-18 ubuntu-20 ubuntu sign upload clean distclean
