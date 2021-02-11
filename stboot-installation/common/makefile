st-out := $(out)/stboot-installation
out-dirs += $(st-out) $(os-out)

data_partition := $(st-out)/data_partition.ext4
host_config := $(st-out)/host_configuration.json
security_config := $(st-out)/security_configuration.json

# TODO extra targets to detect changes in folder
os-out_dirs = $(shell find $(os-out) -type d 2>/dev/null)
os-out_files = $(shell find $(os-out) -type f -name '*' 2>/dev/null)

$(eval $(call CONFIG_DEP,$(data_partition),ST_DATA_PARTITION_SZIZE))
$(data_partition): % : %.config $(os-out) $(os-out_dirs) $(os-out_files)
	@echo "[stboot] Build data partition"
	$(common)/build_data_filesystem.sh $(OUTREDIRECT)
	@echo "[stboot] Done data partition"

$(eval $(call CONFIG_DEP,$(initramfs),ST_LINUXBOOT_VARIANT))
# add cpu ssh public key
ifeq ($(strip $(ST_LINUXBOOT_VARIANT)),debug)
$(initramfs): % : %.config $(u-root_bin) $(security_config) $(ROOT_CERT) $(cpu_bin) $(cpud_bin) $(CPU_SSH_KEYS)
else
$(initramfs): % : %.config $(u-root_bin) $(security_config) $(ROOT_CERT)
endif
	@echo "[stboot] Build initramfs"
	$(common)/build_initramfs.sh $(OUTREDIRECT)
	@echo "[stboot] Done initramfs"

$(eval $(call CONFIG_DEP,$(host_config),ST_PROVISIONING_SERVER_URL|ST_NETWORK_MODE|ST_HOST_IP|ST_HOST_GATEWAY|ST_HOST_DNS))
$(host_config): % : %.config
	@echo "[stboot] Build host configuration"
	$(common)/build_host_config.sh $(OUTREDIRECT)
	@echo "[stboot] Done host configuration"

$(eval $(call CONFIG_DEP,$(security_config),ST_SIGNING_ROOT|ST_NUM_SIGNATURES|ST_BOOT_MODE|ST_USE_PKG_CACHE))
$(security_config): % : %.config
	@echo "[stboot] Build security configuration"
	$(common)/build_security_config.sh $(OUTREDIRECT)
	@echo "[stboot] Done security configuration"
