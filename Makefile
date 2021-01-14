top := $(CURDIR)
obj ?= $(top)/out
cache ?= $(top)/cache

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

NEWEST-OSPGK := $(top)/.newest-ospkgs.zip

all: mbr_bootloader

check:
	@echo Checking dependencies
	$(scripts)/checks.sh

olddefconfig:
	$(scripts)/make_global_config.sh

toolchain: go-tools debos

u-root_bin := $(gopath)/bin/u-root
stmanager_bin := $(gopath)/bin/stmanager
cpu_bin := $(gopath)/bin/cpu
sinit-acm-grebber_bin := $(gopath)/bin/sinit-acm-grebber
go-tools := $(u-root_bin) $(stmanager_bin) $(cpu_bin) $(sinit-acm-grebber_bin)

go-tools-env := gopath=$(gopath)
ifneq ($(strip $(ST_UROOT_DEV_BRANCH)),)
go-tools-env += UROOT_BRANCH=$(ST_UROOT_DEV_BRANCH)
endif

u-root: $(u-root_bin)
stmanager: $(stmanager_bin)
cpu: $(cpu_bin)
sinit-acm-grebber: $(sinit-acm-grebber_bin)
go-tools:
	$(MAKE) -f modules/go.mk $(go-tools-env)
$(go-tools):
	$(MAKE) -f modules/go.mk $@ $(go-tools-env)

debos:
	$(MAKE) -f modules/debos.mk

debos-debian:
	$(MAKE) -f modules/debos.mk debian

debos-ubuntu:
	$(MAKE) -f modules/debos.mk ubuntu

keygen:
	@echo Generate example keys and certificates
	$(scripts)/make_keys_and_certs.sh

debian: debos-debian
	@echo Build debian
	$(os)/debian/make_debian.sh

ubuntu-18: debos-ubuntu
	@echo Build ubuntu
	$(os)/ubuntu/make_ubuntu.sh "18"

ubuntu-20: debos-ubuntu
	@echo Build ubuntu
	$(os)/ubuntu/make_ubuntu.sh "20"

ubuntu: ubuntu-18

sign:
	@echo Sign OS package
	$(scripts)/create_and_sign_os_package.sh

upload: $(NEWEST-OSPKG)
	$(scripts)/upload_os_package.sh $(NEWEST-OSPGK)

mbr_bootloader: $(DOTCONFIG) go-tools
	@echo Generating MBR BOOTLOADER
	$(MAKE) -f $(stboot-installation)/mbr-bootloader/makefile \
		ST_MBR_BOOTLOADER_KERNEL_VERSION=$(ST_MBR_BOOTLOADER_KERNEL_VERSION) \
		ST_MBR_BOOTLOADER_KERNEL_CONFIG=$(ST_MBR_BOOTLOADER_KERNEL_CONFIG)

efi_application: $(DOTCONFIG) u-root
	@echo Generating EFI APPLICATION
	$(MAKE) -f $(stboot-installation)/efi-application/makefile

run-mbr:
	$(scripts)/start_qemu_mbr_bootloader.sh

run-efi:
	$(scripts)/start_qemu_efi_application.sh

$(DOTCONFIG):
	@echo
	@echo Error: run.config file missing.
	@echo        Please provide a config file of run \'make olddefconfig\'
	@echo        to generate a default config.
	@echo
	@exit 1


clean:
	rm -rf $(obj)
	rm -f run.config

distclean: clean
	rm -rf $(cache)

.PHONY: all check olddefconfig toolchain go-tools u-root stmanager cpu sinit-acm-grebber keygen debian ubuntu-18 ubuntu-20 ubuntu sign upload mbr_bootloader efi_application run-mbr run-efi clean distclean
