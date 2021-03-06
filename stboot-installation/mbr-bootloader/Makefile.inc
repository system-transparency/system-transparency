mbr := stboot-installation/mbr-bootloader
mbr-out := $(st-out)/mbr-bootloader

mbr_image:= $(mbr-out)/stboot_mbr_installation.img
mbr_boot_partition := $(mbr-out)/boot_partition.vfat
syslinux := $(cache)/syslinux/syslinux-6.03/bios/mtools/syslinux
syslinux_efi32 := $(cache)/syslinux/syslinux-6.03/efi32/efi/syslinux.efi
syslinux_efi64 := $(cache)/syslinux/syslinux-6.03/efi64/efi/syslinux.efi
efi32 := $(mbr-out)/BOOTIA32.EFI
efi64 := $(mbr-out)/BOOTX64.EFI
syslinux_config := $(mbr-out)/syslinux.cfg

ifeq ($(IS_ROOT),)

mbr-bootloader-installation: $(mbr_image)

$(mbr_image): $(mbr_boot_partition) $(data_partition)
	$(call LOG,INFO,Build MBR bootloader image,$@)
	$(mbr)/build_image.sh $(OUTREDIRECT)
	$(call LOG,DONE,MBR bootloader image,$@)

$(mbr_boot_partition): $(kernel) $(syslinux_config) $(host_config) $(syslinux) $(efi32) $(efi64)
	$(call LOG,INFO,Build STBOOT MBR boot partition,$@)
	$(mbr)/build_boot_filesystem.sh $(OUTREDIRECT)
	$(call LOG,DONE,STBOOT MBR boot partition,$@)

$(syslinux):
	$(call LOG,INFO,Fetch syslinux,$@)
	$(mbr)/fetch_syslinux.sh $(OUTREDIRECT)
	$(call LOG,DONE,syslinux,$@)

$(syslinux_config):
	mkdir -p $(dir $@)
	$(call LOG,INFO,Generating syslinux configuration,$@)
	$(mbr)/build_syslinux_config.sh $(OUTREDIRECT)
	$(call LOG,DONE,syslinux configuration,$@)

$(efi32): $(syslinux)
	cp $(syslinux_efi32) $@

$(efi64): $(syslinux)
	cp $(syslinux_efi64) $@

run-mbr-bootloader: $(call GROUP,$(swtpm_bin) $(swtpm_bin)) $(DOTCONFIG) $(mbr_image)
	$(call LOG,INFO,Run MBR bootloader image,$(mbr_image))
	PATH=$(dir $<):$${PATH} $(scripts)/start_qemu_mbr_bootloader.sh

.PHONY: mbr-bootloader-installation run-mbr-bootloader

endif #ifeq ($(IS_ROOT),)
