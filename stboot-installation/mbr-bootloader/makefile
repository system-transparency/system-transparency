mbr := $(top)/stboot-installation/mbr-bootloader
mbr-out := $(st-out)/mbr-bootloader
out-dirs += $(mbr-out)

mbr_image:= $(mbr-out)/stboot_mbr_installation.img
mbr_boot_partition := $(mbr-out)/boot_partition.vfat
mbr_kernel := $(mbr-out)/linuxboot.vmlinuz
syslinux := $(cache)/syslinux/syslinux-6.03/bios/mtools/syslinux
syslinux_config := $(mbr-out)/syslinux.cfg

$(mbr_image): $(mbr_boot_partition) $(data_partition)
	@echo "\ngenerating: $@"
	$(mbr)/build_image.sh

$(mbr_boot_partition): $(syslinux_config) $(host_config) $(syslinux) $(mbr_kernel)
	@echo "\ngenerating: $@"
	$(mbr)/build_boot_filesystem.sh

$(eval $(call CONFIG_DEP,$(mbr_kernel),ST_LINUXBOOT_CMDLINE|ST_MBR_BOOTLOADER_KERNEL_CONFIG|ST_CUSTOMIZE_KERNEL_CONFIG|ST_MBR_BOOTLOADER_KERNEL_VERSION))
$(mbr_kernel): % : %.config $(initramfs)
	@echo "\ngenerating: $@" 
	$(common)/build_kernel.sh "$(ST_MBR_BOOTLOADER_KERNEL_CONFIG)" "$@" "$(ST_MBR_BOOTLOADER_KERNEL_VERSION)"

$(syslinux):
	@echo "\ngenerating: $@" 
	$(mbr)/fetch_syslinux.sh

$(syslinux_config):
	@echo "\ngenerating: $@" 
	$(mbr)/build_syslinux_config.sh
