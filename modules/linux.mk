mbr-kernel_dir = $(cache)/mbr-kernel
mbr-kernel := $(out)/stboot-installation/mbr-bootloader/linuxboot.vmlinuz
tarball_dir := $(cache)/tarball

ST_KERNEL_VERSION ?= 5.10.10

ifneq ($(strip $(ST_MBR_BOOTLOADER_KERNEL_VERSION)),)
mbr-kernel_version := $(ST_MBR_BOOTLOADER_KERNEL_VERSION)
else
mbr-kernel_version := $(ST_KERNEL_VERSION)
endif

kernel_mirror=https://mirrors.edge.kernel.org/pub/linux/kernel
mbr-kernel_tarball=linux-$(mbr-kernel_version).tar
efi-kernel_tarball=linux-$(efi-kernel_version).tar

ifeq ($(findstring x2.6.,x$(mbr-kernel_version)),x2.6.)
mbr-kernel_mirror_path := $(kernel_mirror)/v2.6
else ifeq ($(findstring x3.,x$(mbr-kernel_version)),x3.)
mbr-kernel_mirror_path := $(kernel_mirror)/v3.x
else ifeq ($(findstring x4.,x$(mbr-kernel_version)),x4.)
mbr-kernel_mirror_path := $(kernel_mirror)/v4.x
else ifeq ($(findstring x5.,x$(mbr-kernel_version)),x5.)
mbr-kernel_mirror_path := $(kernel_mirror)/v5.x
else ifeq ($(findstring x6.,x$(mbr-kernel_version)),x6.)
mbr-kernel_mirror_path := $(kernel_mirror)/v6.x
endif

mbr-kernel_dir := $(cache)/linux/mbr-kernel-$(subst .,_,$(mbr-kernel_version))
kernel_image := arch/x86/boot/bzImage
mbr-kernel_target := $(mbr-kernel_dir)/$(kernel_image)

# file flags
unpack=.unpack
fetch=.fetch

ARCH=x86_64
KERNEL_MAKE_FLAGS = \
	ARCH=$(ARCH)

$(eval $(call CONFIG_DEP,$(mbr-kernel),ST_LINUXBOOT_CMDLINE|ST_MBR_BOOTLOADER_KERNEL_CONFIG|ST_MBR_BOOTLOADER_KERNEL_VERSION))
mbr-kernel $(mbr-kernel): $(mbr-kernel).config $(mbr-kernel_target)
	rsync $(mbr-kernel_target) $(mbr-kernel)
	@echo "[linux] Done MBR kernel"

$(mbr-kernel_target): $(mbr-kernel_dir)/.config  $(initramfs)
	@echo "[linux] Make kernel $(mbr-kernel_version)"
	$(MAKE) -C $(mbr-kernel_dir) $(KERNEL_MAKE_FLAGS) bzImage

$(mbr-kernel_dir)/.config: $(mbr-kernel_dir)/$(unpack) $(patsubst "%",%,$(ST_MBR_BOOTLOADER_KERNEL_CONFIG))
	@echo "[linux] Configure kernel $(mbr-kernel_version)"
ifneq ($(strip $(ST_MBR_BOOTLOADER_KERNEL_CONFIG)),)
	echo "[linux] Use configuration file $(ST_MBR_BOOTLOADER_KERNEL_CONFIG)"
	cp $(ST_MBR_BOOTLOADER_KERNEL_CONFIG) $(mbr-kernel_dir)/.config
endif
	$(MAKE) -C $(mbr-kernel_dir) $(KERNEL_MAKE_FLAGS) olddefconfig

$(mbr-kernel_dir)/$(unpack): $(tarball_dir)/$(mbr-kernel_tarball)$(fetch)
	if [[ -d "$(mbr-kernel_dir)" && ! -f "$(mbr-kernel_dir)/$(decompress_flag)" ]]; then \
	rm -rf $(mbr-kernel_dir); \
	fi
	if [[ ! -d "$(mbr-kernel_dir)" ]]; then \
	mkdir -p $(mbr-kernel_dir); \
	echo "[linux] Unpack $(mbr-kernel_tarball).xz"; \
	tar xJf $(tarball_dir)/$(mbr-kernel_tarball).xz --strip 1 -C $(mbr-kernel_dir); \
	fi
	touch $@

$(tarball_dir)/$(mbr-kernel_tarball)$(fetch):
ifneq ($(shell [[ -d "$(kernel_dir)" && -f "$(kernel_dir)/$(decompress_flag)" ]];echo $$?),0)
	mkdir -p $(tarball_dir)
	if [[ ! -f $(tarball_dir)/$(mbr-kernel_tarball).xz && ! -f $(tarball_dir)/$(mbr-kernel_tarball).xz ]]; then \
	echo "[linux] Get $(mbr-kernel_tarball).xz"; \
	cd $(tarball_dir); \
	curl -OLSs "$(mbr-kernel_mirror_path)/$(mbr-kernel_tarball).xz"; \
	cd -; \
	fi
	touch $@
endif

.PHONY: mbr-kernel
