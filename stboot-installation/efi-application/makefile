efi := $(top)/stboot-installation/efi-application
efi-out := $(st-out)/efi-application
out-dirs += $(efi-out)

efi_image:= $(efi-out)/stboot_efi_installation.img
efi_boot_partition := $(efi-out)/boot_partition.vfat
efi_kernel := $(efi-out)/linuxboot.efi


efi-application-installation $(efi_image): $(efi_boot_partition) $(data_partition)
	@echo "[stboot] Build EFI application image"
	$(efi)/build_image.sh $(OUTREDIRECT)
	@echo "[stboot] Done EFI application image"

$(efi_boot_partition): $(host_config) $(efi_kernel)
	@echo "[stboot] Build EFI partition"
	$(efi)/build_boot_filesystem.sh $(OUTREDIRECT)
	@echo "[stboot] Done EFI partition"

$(eval $(call CONFIG_DEP,$(efi_kernel),ST_LINUXBOOT_CMDLINE|ST_EFI_APPLICATION_EFISTUB_KERNEL_CONFIG|ST_CUSTOMIZE_KERNEL_CONFIG|ST_EFI_APPLICATION_EFISTUB_KERNEL_VERSION))
$(efi_kernel): % : %.config $(initramfs)
	@echo "[stboot] Build EFI kernel"
	$(common)/build_kernel.sh "$(ST_EFI_APPLICATION_EFISTUB_KERNEL_CONFIG)" "$@" "$(ST_EFI_APPLICATION_EFISTUB_KERNEL_VERSION)" $(OUTREDIRECT)
	@echo "[stboot] Done EFI kernel"

run-efi-application: $(DOTCONFIG) $(efi_image)
	@echo "[stboot] Run EFI application image"
	$(scripts)/start_qemu_efi_application.sh

.PHONY: efi-application-installation run-efi-application
