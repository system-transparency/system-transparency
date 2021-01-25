mbr-kernel_dir := $(cache)/mbr-kernel
mbr-kernel := $(out)/stboot-installation/mbr-bootloader/linuxboot.vmlinuz
tarball_dir := $(cache)/tarball
kernel_mirror=https://mirrors.edge.kernel.org/pub/linux/kernel
kernel_image := arch/x86/boot/bzImage

ST_KERNEL_VERSION ?= 5.10.10

# file flags
unpack=.unpack
fetch=.fetch

KERNEL_MAKE_FLAGS = \
	ARCH=x86_64


define KERNEL_MIRROR_PATH
ifeq ($(findstring x2.6.,x$1),x2.6.)
$1_kernel_mirror_path := $(kernel_mirror)/v2.6
else ifeq ($(findstring x3.,x$1),x3.)
$1_kernel_mirror_path := $(kernel_mirror)/v3.x
else ifeq ($(findstring x4.,x$1),x4.)
$1_kernel_mirror_path := $(kernel_mirror)/v4.x
else ifeq ($(findstring x5.,x$1),x5.)
$1_kernel_mirror_path := $(kernel_mirror)/v5.x
else ifeq ($(findstring x6.,x$1),x6.)
$1_kernel_mirror_path := $(kernel_mirror)/v6.x
endif
endef

# fetch linux tarball
$(tarball_dir)/linux-%.tar.xz$(fetch):
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	mkdir -p $(tarball_dir)
	@echo "[linux] Get $($*_kernel_tarball)"
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	cd $(tarball_dir) && curl -OLSs $($*_kernel_mirror_path)/linux-$*.tar.xz
	touch $@

### KERNEL_TARGET: function to generate linux kernel targets for specific installations
## args
#
# $1: name           - "installation name (e.g. mbr, efi ...)"
# $2: kernel_path    - "kernel path"
# $3: kernel_version - "kernel version"
# $4: defconfig      - "kernel defconfig"

define KERNEL_TARGET

ifneq ($$(strip $3),)
$1-kernel_version := $3
else
$1-kernel_version := $(ST_KERNEL_VERSION)
endif

$1-kernel_tarball=linux-$$($1-kernel_version).tar.xz
$1-kernel_dir := $(cache)/linux/$1-kernel-$$(subst .,_,$$($1-kernel_version))
$1-kernel_target := $$($1-kernel_dir)/$(kernel_image)

$1-kernel $2: $$($1-kernel_target)
	mkdir -p `dirname $2`
	rsync -c $$($1-kernel_target) $2
	@echo "[$1-linux] Done kernel"

$$($1-kernel_target): $$($1-kernel_dir)/.config  $(initramfs)
	@echo "[$1-linux] Make kernel $$($1-kernel_version)"
	$$(MAKE) -C $$($1-kernel_dir) $$(KERNEL_MAKE_FLAGS) bzImage

$$($1-kernel_dir)/.config: $$($1-kernel_dir)/$(unpack) $$(patsubst "%",%,$4)
	@echo "[$1-linux] Configure kernel $$($1-kernel_version)"
ifneq ($$(strip $4),)
	echo "[$1-linux] Use configuration file $4"
	cp $4 $$($1-kernel_dir)/.config
endif
	$$(MAKE) -C $$($1-kernel_dir) $(KERNEL_MAKE_FLAGS) olddefconfig

$$($1-kernel_dir)/$(unpack): $(tarball_dir)/$$($1-kernel_tarball)$(fetch)
	if [[ -d "$$($1-kernel_dir)" && ! -f "$$($1-kernel_dir)/$(fetch)" ]]; then \
	rm -rf $$($1-kernel_dir); \
	fi
	if [[ ! -d "$$($1-kernel_dir)" ]]; then \
	mkdir -p $$($1-kernel_dir); \
	echo "[$1-linux] Unpack $$($1-kernel_tarball).xz"; \
	tar xJf $(tarball_dir)/$$($1-kernel_tarball) --strip 1 -C $$($1-kernel_dir); \
	fi
	touch $$@

.PHONY: $1-kernel

endef
