cb := $(top)/stboot-installation/coreboot-payload
cb-out := $(st-out)/coreboot-payload
out-dirs += $(coreboot-out)

cb_firmware := $(cb-out)/stboot_coreboot_installation.rom
cb_firmware_empty := $(cb-out)/no_payload_coreboot.rom
cb_image := $(cb-out)/stboot_coreboot_installation.img
cb_boot_partition := $(cb-out)/boot_partition.vfat
cb_kernel := $(cb-out)/linuxboot.vmlinuz
cb_version := 4.13

cb_config := $(patsubst "%",%,$(ST_COREBOOT_PAYLOAD_FIRMWARE_CONFIG))

coreboot-payload-installation: $(cb_firmware) $(cb_image)

$(cb_firmware): $(cb_kernel) $(initramfs) $(cb_firmware_empty) $(cbfstool)
	@echo "[stboot] Build coreboot firmware image"
	cp $(cb_firmware_empty) $@.tmp
	$(cbfstool) $@.tmp add-payload -f$(cb_kernel) -I $(initramfs) -C $(ST_LINUXBOOT_CMDLINE) -n fallback/payload
	rsync -c $@.tmp $@
	rm $@.tmp
	@echo "[stboot] Done coreboot firmware image"

$(cb_firmware_empty): $(cb_dir)/coreboot-$(cb_version)/.config $(cb_dir)/coreboot-$(cb_version)/.xcompile
	$(MAKE) -C $(cb_dir)/coreboot-$(cb_version)
	rsync -c $(dir $<)/build/coreboot.rom $@

$(cb_dir)/coreboot-$(cb_version)/.config: $(cb_config) $(cb_dir)/coreboot-$(cb_version)/.unpack
	cp $< $@
	$(MAKE) -C $(dir $@) olddefconfig

$(cb_image): $(cb_boot_partition) $(data_partition)
	@echo "[stboot] Build coreboot disk image"
	$(cb)/build_image.sh $(OUTREDIRECT)
	@echo "[stboot] Done coreboot disk image"

$(cb_boot_partition): $(host_config) $(cb_kernel)
	@echo "[stboot] Build coreboot boot partition"
	$(cb)/build_boot_filesystem.sh $(OUTREDIRECT)
	@echo "[stboot] Done coreboot boot partition"

$(eval $(call CONFIG_DEP,$(cb_kernel),ST_LINUXBOOT_CMDLINE|ST_COREBOOT_PAYLOAD_KERNEL_CONFIG|ST_COREBOOT_PAYLOAD_KERNEL_VERSION))
$(eval $(call KERNEL_TARGET,cb,$(cb_kernel),$(ST_COREBOOT_PAYLOAD_KERNEL_VERSION),$(ST_COREBOOT_PAYLOAD_KERNEL_CONFIG)))
$(cb_kernel): % : %.config

run-coreboot-payload: $(DOTCONFIG) $(cb_firmware) $(cb_image)
	@echo "[stboot] Run coreboot payload image"
	$(scripts)/start_qemu_coreboot_payload.sh

.PHONY: coreboot-payload-installation run-coreboot-payload
