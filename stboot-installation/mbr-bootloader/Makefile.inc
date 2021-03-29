mbr := stboot-installation/mbr-bootloader
mbr-out := $(st-out)/mbr-bootloader
out-dirs += $(mbr-out)

mbr_image:= $(mbr-out)/stboot_mbr_installation.img
mbr_boot_partition := $(mbr-out)/boot_partition.vfat
mbr_kernel := $(mbr-out)/linuxboot.vmlinuz
syslinux := $(cache)/syslinux/syslinux-6.03/bios/mtools/syslinux
syslinux_config := $(mbr-out)/syslinux.cfg

mbr-bootloader-installation: $(mbr_image)

$(mbr_image): $(mbr_boot_partition) $(data_partition)
	$(call LOG,INFO,Build MBR bootloader image,$@)
	$(mbr)/build_image.sh $(OUTREDIRECT)
	$(call LOG,DONE,MBR bootloader image,$@)

$(mbr_boot_partition): $(mbr_kernel) $(syslinux_config) $(host_config) $(syslinux)
	$(call LOG,INFO,Build STBOOT MBR boot partition,$@)
	$(mbr)/build_boot_filesystem.sh $(OUTREDIRECT)
	$(call LOG,DONE,STBOOT MBR boot partition,$@)

$(eval $(call CONFIG_DEP,$(mbr_kernel),ST_LINUXBOOT_CMDLINE|ST_MBR_BOOTLOADER_KERNEL_CONFIG|ST_MBR_BOOTLOADER_KERNEL_VERSION))
$(eval $(call KERNEL_TARGET,mbr,$(mbr_kernel),$(ST_MBR_BOOTLOADER_KERNEL_VERSION),$(ST_MBR_BOOTLOADER_KERNEL_CONFIG)))
$(mbr_kernel): % : %.config

$(syslinux):
	$(call LOG,INFO,Fetch syslinux,$@)
	$(mbr)/fetch_syslinux.sh $(OUTREDIRECT)
	$(call LOG,DONE,syslinux,$@)

$(syslinux_config):
	$(call LOG,INFO,Generating syslinux configuration,$@)
	$(mbr)/build_syslinux_config.sh $(OUTREDIRECT)
	$(call LOG,DONE,syslinux configuration,$@)

run-mbr-bootloader: $(DOTCONFIG) $(mbr_image)
	$(call LOG,INFO,Run MBR bootloader image,$(mbr_image))
	$(scripts)/start_qemu_mbr_bootloader.sh

.PHONY: mbr-bootloader-installation run-mbr-bootloader
