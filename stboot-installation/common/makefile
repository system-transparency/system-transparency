st-out := $(top)/out/stboot-installation
os-out = $(top)/out/os-packages/
out-dirs += $(st-out) $(os-out)

data_partition := $(st-out)/data_partition.ext4
initramfs := $(st-out)/initramfs-linuxboot.cpio.gz
host_config := $(st-out)/host_configuration.json
security_config := $(st-out)/security_configuration.json

# TODO extra targets to detect changes in folder
os-out_dirs = $(shell find $(os-out) -type d 2>/dev/null)
os-out_files = $(shell find $(os-out) -type f -name '*' 2>/dev/null)

$(eval $(call CONFIG_DEP,$(data_partition),ST_DATA_PARTITION_SZIZE))
$(data_partition): % : %.config $(os-out) $(os-out_dirs) $(os-out_files)
	@echo "\ngenerating: $@"
	$(common)/build_data_filesystem.sh

$(eval $(call CONFIG_DEP,$(initramfs),ST_LINUXBOOT_VARIANT))
$(initramfs): % : %.config $(cache)/go/bin/u-root $(security_config) $(patsubst "%",%,$(ST_SIGNING_ROOT))
	@echo "\ngenerating: $@"
	$(common)/build_initramfs.sh

$(eval $(call CONFIG_DEP,$(host_config),ST_PROVISIONING_SERVER_URL|ST_NETWORK_MODE|ST_HOST_IP|ST_HOST_GATEWAY|ST_HOST_DNS))
$(host_config): % : %.config
	@echo "\ngenerating: $@" 
	$(common)/build_host_config.sh

$(eval $(call CONFIG_DEP,$(security_config),ST_SIGNING_ROOT|ST_NUM_SIGNATURES|ST_BOOT_MODE))
$(security_config): % : %.config
	$(common)/build_security_config.sh
