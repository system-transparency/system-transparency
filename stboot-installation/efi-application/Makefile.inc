efi := stboot-installation/efi-application
efi-out := $(st-out)/efi-application

efi_image:= $(efi-out)/stboot_efi_installation.img
efi_boot_partition := $(efi-out)/boot_partition.vfat
efi_kernel := $(efi-out)/linuxboot.efi

ifeq ($(IS_ROOT),)

efi-application-installation: $(efi_image)

$(efi_image): $(efi_boot_partition) $(data_partition)
	$(call LOG,INFO,Build EFI application image,$@)
	$(efi)/build_image.sh $(OUTREDIRECT)
	$(call LOG,DONE,EFI application image,$@)

$(efi_boot_partition): $(host_config) $(efi_kernel)
	$(call LOG,INFO,Build STBOOT EFI boot partition,$@)
	$(efi)/build_boot_filesystem.sh $(OUTREDIRECT)
	$(call LOG,DONE,STBOOT EFI boot partition,$@)

$(eval $(call CONFIG_DEP,$(efi_kernel),ST_LINUXBOOT_CMDLINE|ST_EFI_APPLICATION_EFISTUB_KERNEL_CONFIG|ST_CUSTOMIZE_KERNEL_CONFIG|ST_EFI_APPLICATION_EFISTUB_KERNEL_VERSION))
$(eval $(call KERNEL_TARGET,efi,$(efi_kernel),$(ST_EFI_APPLICATION_EFISTUB_KERNEL_VERSION),$(ST_EFI_APPLICATION_EFISTUB_KERNEL_CONFIG)))
$(efi_kernel): % : %.config

run-efi-application: $(swtpm_bin) $(DOTCONFIG) $(efi_image)
	$(call LOG,INFO,Run EFI application image,$(mbr_image))
	PATH=$(dir $<):$${PATH} $(scripts)/start_qemu_efi_application.sh

.PHONY: efi-application-installation run-efi-application

endif #ifeq ($(IS_ROOT),)
