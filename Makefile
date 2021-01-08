top := $(CURDIR)
obj ?= $(top)/out
build ?= $(top)/cache

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

toolchain:
	@echo Install toolchain
	$(scripts)/make_toolchain.sh

keygen:
	@echo Generate example keys and certificates
	$(scripts)/make_keys_and_certs.sh

debian: toolchain
	@echo Build debian
	$(os)/debian/make_debian.sh

ubuntu-18: toolchain
	@echo Build ubuntu
	$(os)/ubuntu/make_ubuntu.sh "18"

ubuntu-20: toolchain
	@echo Build ubuntu
	$(os)/ubuntu/make_ubuntu.sh "20"

ubuntu: ubuntu-18

sign:
	@echo Sign OS package
	$(scripts)/create_and_sign_os_package.sh

upload: $(NEWEST-OSPKG)
	$(scripts)/upload_os_package.sh $(NEWEST-OSPGK)

mbr_bootloader:
	@echo Generating MBR BOOTLOADER
	$(stboot-installation)/mbr-bootloader/make_mbr_bootloader.sh

efi_application:
	@echo Generating EFI APPLICATION
	$(stboot-installation)/efi-application/make_efi_application.sh

run-mbr:
	$(scripts)/start_qemu_mbr_bootloader.sh

run-efi:
	$(scripts)/start_qemu_efi_application.sh

clean:
	rm -rf $(obj)
	rm -f run.config

distclean: clean
	rm -rf $(build)

.PHONY: all check olddefconfig toolchain keygen debian ubuntu-18 ubuntu-20 ubuntu sign upload mbr_bootloader efi_application run-mbr run-efi clean distclean
