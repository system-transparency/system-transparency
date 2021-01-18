efi := $(top)/stboot-installation/efi-application
efi-out := $(st-out)/efi-application
out-dirs += $(efi-out)

efi_image:= $(efi-out)/stboot_efi_installation.img
efi_boot_partition := $(efi-out)/boot_partition.vfat
efi_kernel := $(efi-out)/linuxboot.efi

$(efi_image): $(efi_boot_partition) $(data_partition)
	@echo "\ngenerating: $@"
	$(efi)/build_image.sh

$(efi_boot_partition): $(host_config) $(efi_kernel)
	@echo "\ngenerating: $@"
	$(efi)/build_boot_filesystem.sh

$(eval $(call CONFIG_DEP,$(efi_kernel),ST_LINUXBOOT_CMDLINE|ST_EFI_APPLICATION_EFISTUB_KERNEL_CONFIG|ST_CUSTOMIZE_KERNEL_CONFIG|ST_EFI_APPLICATION_EFISTUB_KERNEL_VERSION))
$(efi_kernel): % : %.config $(initramfs)
	@echo "\ngenerating: $@" 
	$(common)/build_kernel.sh "$(ST_EFI_APPLICATION_EFISTUB_KERNEL_CONFIG)" "$@" "$(ST_EFI_APPLICATION_EFISTUB_KERNEL_VERSION)"
