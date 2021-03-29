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
	@echo "[stboot] Build MBR bootloader image"
	$(mbr)/build_image.sh $(OUTREDIRECT)
	@echo "[stboot] Done MBR bootloader image"

$(mbr_boot_partition): $(mbr_kernel) $(syslinux_config) $(host_config) $(syslinux)
	@echo "[stboot] Build MBR boot partition"
	$(mbr)/build_boot_filesystem.sh $(OUTREDIRECT)
	@echo "[stboot] Done MBR boot partition"

$(eval $(call CONFIG_DEP,$(mbr_kernel),ST_LINUXBOOT_CMDLINE|ST_MBR_BOOTLOADER_KERNEL_CONFIG|ST_MBR_BOOTLOADER_KERNEL_VERSION))
$(eval $(call KERNEL_TARGET,mbr,$(mbr_kernel),$(ST_MBR_BOOTLOADER_KERNEL_VERSION),$(ST_MBR_BOOTLOADER_KERNEL_CONFIG)))
$(mbr_kernel): % : %.config

$(syslinux):
	@echo "[stboot] Fetch syslinux"
	$(mbr)/fetch_syslinux.sh $(OUTREDIRECT)
	@echo "[stboot] Done syslinux"

$(syslinux_config):
	@echo "[stboot] Generating syslinux configuration"
	$(mbr)/build_syslinux_config.sh $(OUTREDIRECT)
	@echo "[stboot] Done syslinux configuration"

run-mbr-bootloader: $(DOTCONFIG) $(mbr_image)
	@echo "[stboot] Run MBR bootloader image"
	$(scripts)/start_qemu_mbr_bootloader.sh

.PHONY: mbr-bootloader-installation run-mbr-bootloader
