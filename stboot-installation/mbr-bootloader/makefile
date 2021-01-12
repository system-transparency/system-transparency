top := $(CURDIR)
cache := $(top)/cache
common := $(top)/stboot-installation/common
mbr := $(top)/stboot-installation/mbr-bootloader

out := $(top)/out/stboot-installation
mbr-out := $(out)/mbr-bootloader

mbr-image:= $(mbr-out)/stboot_mbr_installation.img


all: $(mbr-image)

$(mbr-image): $(mbr-out)/boot_partition.vfat $(out)/data_partition.ext4
	@echo "\ngenerating: $@"
	$(mbr)/build_image.sh

$(mbr-out)/boot_partition.vfat: $(mbr-out)/syslinux.cfg $(out)/host_configuration.json $(cache)/syslinux/syslinux-6.03/bios/mtools/syslinux $(mbr-out)/linuxboot.vmlinuz
	@echo "\ngenerating: $@"
	$(mbr)/build_boot_filesystem.sh

# TODO extra targets to detect changes in folder
ASSET_MAIN = $(top)/out/os-packages/
ASSET_DIRS = $(shell find $(ASSET_MAIN) -type d)
ASSET_FILES = $(shell find $(ASSET_MAIN) -type f -name '*')

$(ASSET_MAIN):
	mkdir -p $(ASSET_MAIN)

$(out)/data_partition.ext4: $(ASSET_MAIN) $(ASSET_DIRS) $(ASSET_FILES)
	@echo "\ngenerating: $@"
	$(common)/build_data_filesystem.sh

$(mbr-out)/syslinux.cfg:
	@echo "\ngenerating: $@" 
	$(mbr)/build_syslinux_config.sh

$(out)/host_configuration.json:
	@echo "\ngenerating: $@" 
	$(common)/build_host_config.sh

$(cache)/syslinux/syslinux-6.03/bios/mtools/syslinux:
	@echo "\ngenerating: $@" 
	$(mbr)/fetch_syslinux.sh

$(mbr-out)/linuxboot.vmlinuz: $(top)/run.config $(out)/initramfs-linuxboot.cpio.gz
	@echo "\ngenerating: $@" 
	$(common)/build_kernel.sh "$(ST_MBR_BOOTLOADER_KERNEL_CONFIG)" "$(mbr-out)/linuxboot.vmlinuz" "$(ST_MBR_BOOTLOADER_KERNEL_VERSION)"

$(out)/initramfs-linuxboot.cpio.gz: $(out)/security_configuration.json
	@echo "\ngenerating: $@" 
	$(common)/build_initramfs.sh

$(out)/security_configuration.json:
	$(common)/build_security_config.sh

.PHONY: all
