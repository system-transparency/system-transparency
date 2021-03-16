os-out := $(out)/os-packages
st-out := $(out)/stboot-installation
out-dirs += $(st-out) $(os-out)

data_partition := $(st-out)/data_partition.ext4
initramfs := $(out)/stboot-installation/initramfs-linuxboot.cpio.gz
host_config := $(st-out)/host_configuration.json
security_config := $(st-out)/security_configuration.json

# TODO extra targets to detect changes in folder
os-out_dirs = $(shell find $(os-out) -type d 2>/dev/null)
os-out_files = $(shell find $(os-out) -type f -name '*' 2>/dev/null)

$(eval $(call CONFIG_DEP,$(data_partition),ST_DATA_PARTITION_SZIZE))
# build and sign example os-package, if directy is empty
ifeq ($(os-out_files),)
$(data_partition): % : %.config example-os-package
else
$(data_partition): % : %.config $(os-out) $(os-out_dirs) $(os-out_files)
endif
	@$(call LOG,INFO,Build STDATA partition,$(data_partition))
	$(common)/build_data_filesystem.sh $(OUTREDIRECT)
	@$(call LOG,DONE,STDATA,$(data_partition))

$(eval $(call CONFIG_DEP,$(initramfs),ST_LINUXBOOT_VARIANT))
# add cpu ssh public key
ifeq ($(strip $(ST_LINUXBOOT_VARIANT)),debug)
$(initramfs): % : %.config $(u-root_bin) $(security_config) $(ROOT_CERT) $(call GROUP,$(CPU_SSH_KEYS)) $(call GROUP,$(cpu_bin) $(cpud_bin))
else
$(initramfs): % : %.config $(u-root_bin) $(security_config) $(ROOT_CERT)
endif
	@$(call LOG,INFO,Build LinuxBoot initramfs,$@)
	$(common)/build_initramfs.sh $(OUTREDIRECT)
	@$(call LOG,DONE,LinuxBoot initramfs,$@)

$(eval $(call CONFIG_DEP,$(host_config),ST_PROVISIONING_SERVER_URL|ST_NETWORK_MODE|ST_HOST_IP|ST_HOST_GATEWAY|ST_HOST_DNS))
$(host_config): % : %.config
	@$(call LOG,INFO,Build host configuration,$@)
	$(common)/build_host_config.sh $(OUTREDIRECT)
	@$(call LOG,DONE,host configuration,$@)

$(eval $(call CONFIG_DEP,$(security_config),ST_SIGNING_ROOT|ST_NUM_SIGNATURES|ST_BOOT_MODE|ST_USE_PKG_CACHE))
$(security_config): % : %.config
	@$(call LOG,INFO,Build security configuration,$@)
	$(common)/build_security_config.sh $(OUTREDIRECT)
	@$(call LOG,DONE,security configuration,$@)
