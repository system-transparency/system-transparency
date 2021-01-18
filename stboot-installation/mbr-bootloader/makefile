mbr := $(top)/stboot-installation/mbr-bootloader
st-out := $(top)/out/stboot-installation
mbr-out := $(st-out)/mbr-bootloader
os-out = $(top)/out/os-packages/
out-dirs += $(mbr) $(st-out) $(mbr-out) $(os-out)

mbr-image:= $(mbr-out)/stboot_mbr_installation.img
boot_partition := $(mbr-out)/boot_partition.vfat
data_partition := $(st-out)/data_partition.ext4
syslinux := $(cache)/syslinux/syslinux-6.03/bios/mtools/syslinux
kernel := $(mbr-out)/linuxboot.vmlinuz
initramfs := $(st-out)/initramfs-linuxboot.cpio.gz
host_config := $(st-out)/host_configuration.json
security_config := $(st-out)/security_configuration.json

$(mbr-image): $(boot_partition) $(data_partition)
	@echo "\ngenerating: $@"
	$(mbr)/build_image.sh

$(boot_partition): $(mbr-out)/syslinux.cfg $(host_config) $(syslinux) $(kernel)
	@echo "\ngenerating: $@"
	$(mbr)/build_boot_filesystem.sh

# TODO extra targets to detect changes in folder
os-out_dirs = $(shell find $(os-out) -type d 2>/dev/null)
os-out_files = $(shell find $(os-out) -type f -name '*' 2>/dev/null)

$(eval $(call CONFIG_DEP,$(data_partition),ST_DATA_PARTITION_SZIZE))
$(data_partition): % : %.config $(os-out) $(os-out_dirs) $(os-out_files)
	@echo "\ngenerating: $@"
	$(common)/build_data_filesystem.sh

$(eval $(call CONFIG_DEP,$(kernel),ST_LINUXBOOT_CMDLINE|ST_MBR_BOOTLOADER_KERNEL_CONFIG|ST_CUSTOMIZE_KERNEL_CONFIG|ST_MBR_BOOTLOADER_KERNEL_VERSION))
$(kernel): % : %.config $(initramfs)
	@echo "\ngenerating: $@" 
	$(common)/build_kernel.sh "$(ST_MBR_BOOTLOADER_KERNEL_CONFIG)" "$@" "$(ST_MBR_BOOTLOADER_KERNEL_VERSION)"

$(eval $(call CONFIG_DEP,$(initramfs),ST_LINUXBOOT_VARIANT))
$(initramfs): % : %.config $(cache)/go/bin/u-root $(security_config)
	@echo "\ngenerating: $@"
	$(common)/build_initramfs.sh

$(eval $(call CONFIG_DEP,$(host_config),ST_PROVISIONING_SERVER_URL|ST_NETWORK_MODE|ST_HOST_IP|ST_HOST_GATEWAY|ST_HOST_DNS))
$(host_config): % : %.config
	@echo "\ngenerating: $@" 
	$(common)/build_host_config.sh

$(eval $(call CONFIG_DEP,$(security_config),ST_ROOTCERT_FINGERPRINT_FILE|ST_NUM_SIGNATURES|ST_BOOT_MODE))
$(security_config): % : %.config
	$(common)/build_security_config.sh

$(syslinux):
	@echo "\ngenerating: $@" 
	$(mbr)/fetch_syslinux.sh

$(mbr-out)/syslinux.cfg:
	@echo "\ngenerating: $@" 
	$(mbr)/build_syslinux_config.sh

.PHONY: all
