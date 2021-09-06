OUT ?= out
CACHE ?= cache

# use bash (nix/NixOS friendly)
SHELL := /usr/bin/env bash -euo pipefail -c

# Make is silent per default, but 'make V=1' will show all compiler calls.
Q:=@
ifneq ($(V),1)
ifneq ($(Q),)
.SILENT:
MAKEFLAGS += -s
OUTREDIRECT :=  > /dev/null
endif
endif

# Make uses maximal available job threads by default
ifeq ($(MAKELEVEL),0)
MAKEFLAGS += -j$(shell nproc)
endif

KERNEL ?= linuxboot.vmlinuz

kernel := $(OUT)/linuxboot.vmlinuz
gpg_dir := $(CACHE)/gnupg
gpg_keyring := $(gpg_dir)/keyring.gpg
tarball_dir := $(CACHE)/tarball
kernel_mirror := https://cdn.kernel.org/pub/linux/kernel
kernel_image := arch/x86/boot/bzImage
kernel_dev_1 := torvalds@kernel.org
kernel_dev_2 := gregkh@kernel.org

KERNEL_MAKE_FLAGS := ARCH=x86_64
DEFAULT_CMDLINE="console=ttyS0,115200"
# escape Quotes
_ST_LINUXBOOT_CMDLINE := $(shell echo '$(ST_LINUXBOOT_CMDLINE)' | sed 's/"/\\\\"/g')

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

kernel_version := $(ST_LINUXBOOT_KERNEL_VERSION)
kernel_defconfig := $(ST_LINUXBOOT_KERNEL_CONFIG)
kernel_tarball=linux-$(kernel_version).tar.xz
kernel_tarball_sign=linux-$(kernel_version).tar.sign
kernel_dir := $(CACHE)/linux/kernel-$(subst .,_,$(kernel_version))
kernel_target := $(kernel_dir)/$(kernel_image)

all kernel: $(KERNEL)

$(KERNEL): % : $(kernel_target)
	mkdir -p $(dir $@)
	cp $< $@

$(gpg_keyring):
	mkdir -p -m 700 "$(gpg_dir)"
	@echo "Fetch kernel developer keys"
	gpg -q --batch --homedir "$(gpg_dir)" --auto-key-locate wkd --locate-keys $(kernel_dev_1) $(kernel_dev_2) >/dev/null
	gpg -q --batch --homedir "$(gpg_dir)" --no-default-keyring --export $(kernel_dev_1) $(kernel_dev_2) > $(gpg_keyring)

# fetch linux tarball
$(tarball_dir)/linux-%.tar.xz:
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	mkdir -p $(tarball_dir)
	@echo "Get $($*_kernel_tarball)"
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	wget -qP $(tarball_dir) $($*_kernel_mirror_path)/$($*_kernel_tarball)

# fetch linux tarball signature
$(tarball_dir)/linux-%.tar.sign:
	$(eval $*_kernel_sign := linux-$*.tar.sign)
	mkdir -p $(tarball_dir)
	@echo "Get $($*_kernel_sign)"
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	wget -qP $(tarball_dir) $($*_kernel_mirror_path)/$($*_kernel_sign)

# TODO: verify sha256sum signature
# fetch linux tarball sha256
$(tarball_dir)/linux-%.tar.asc:
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	$(eval $*_kernel_sha := linux-$*.tar.asc)
	mkdir -p $(tarball_dir)
	@echo "Get $($*_kernel_sha)"
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	wget -qP $(tarball_dir) -O - $($*_kernel_mirror_path)/sha256sums.asc \
		| grep "$($*_kernel_tarball)" > $@

# check linux tarball sha256sum
$(tarball_dir)/linux-%.tar.checksum: $(tarball_dir)/linux-%.tar.xz $(tarball_dir)/linux-%.tar.asc
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	$(eval $*_kernel_sha := linux-$*.tar.asc)
	@echo "Check sha256 $($*_kernel_tarball)"
	if ! (cd $(tarball_dir) && sha256sum -c $($*_kernel_sha)); then \
	  >&2 echo "ERROR: sha256 missmatch,$($*_kernel_tarball))"; \
	  echo "Moving $($*_kernel_tarball) to .invalid.$($*_kernel_tarball)"; \
	  mv $(tarball_dir)/$($*_kernel_tarball) $(tarball_dir)/.invalid.$($*_kernel_tarball); \
	  >&2 echo "Rerun to download $($*_kernel_tarball)"; \
	  exit 1; \
	fi
	touch $@

# verify linux tarball
$(tarball_dir)/linux-%.tar.xz.valid: $(tarball_dir)/linux-%.tar.xz $(tarball_dir)/linux-%.tar.sign $(tarball_dir)/linux-%.tar.checksum $(gpg_keyring)
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	$(eval $*_kernel_sign := linux-$*.tar.sign)
	if ! xz -t $(tarball_dir)/$($*_kernel_tarball); then \
		>&2 echo "ERROR: Bad integrity,$($*_kernel_tarball)"; \
	  exit 1; \
	fi
	@echo "Verify $($*_kernel_tarball)"
	if [[ "`xz -cd $(tarball_dir)/$($*_kernel_tarball) | \
	  gpgv -q --homedir "$(gpg_dir)" "--keyring=$(gpg_keyring)" --status-fd=1 $(tarball_dir)/$($*_kernel_sign) - | \
	  grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)';`" -lt 2 ]]; then \
	  >&2 ERROR: Verification failed: $($*_kernel_tarball); \
	  exit 1; \
	else \
	  echo "Verification successful:,$($*_kernel_tarball)"; \
	fi;
	touch $@

$(kernel_target): $(kernel_dir)/.config  $(initramfs)
	@echo "Make kernel v$(kernel_version)"
	$(MAKE) -C $(kernel_dir) $(KERNEL_MAKE_FLAGS) bzImage
	touch $@

$(kernel_dir)/.config: $(DOTCONFIG) $(kernel_dir)/.unpack $(patsubst "%",%,$(ST_LINUXBOOT_KERNEL_CONFIG))
	@echo "Configure kernel $(kernel_version)"
ifneq ($(strip $(ST_LINUXBOOT_KERNEL_CONFIG)),)
	@echo "Use configuration file $(patsubst "%",%,$(ST_LINUXBOOT_KERNEL_CONFIG))"
	cp $(ST_LINUXBOOT_KERNEL_CONFIG) $@.tmp
ifneq ($(strip $(ST_LINUXBOOT_CMDLINE)),)
	@echo 'Overriding CONFIG_CMDLINE with ST_LINUXBOOT_CMDLINE'
	sed -ie 's/CONFIG_CMDLINE=.*/CONFIG_CMDLINE="$(_ST_LINUXBOOT_CMDLINE)"/g' $@.tmp
endif
	mv $@.tmp $@
endif
	$(MAKE) -C $(kernel_dir) $(KERNEL_MAKE_FLAGS) olddefconfig

$(kernel_dir)/.unpack: $(tarball_dir)/$(kernel_tarball).valid
	if [[ -d "$(kernel_dir)" && ! -f "$(kernel_dir)/.unpack" ]]; then \
	rm -rf $(kernel_dir); \
	fi
	if [[ ! -d "$(kernel_dir)" ]]; then \
	mkdir -p $(kernel_dir); \
	echo "Unpack $(kernel_tarball)"; \
	tar xJf $(tarball_dir)/$(kernel_tarball) --strip 1 -C $(kernel_dir); \
	fi
	touch $@

kernel-updatedefconfig: $(kernel_dir)/.config $(DOTCONFIG)
	@echo "Update defconfig $(ST_LINUXBOOT_KERNEL_CONFIG)"
	$(MAKE) -C $(kernel_dir) $(KERNEL_MAKE_FLAGS) savedefconfig
	sed -ie "s/CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"$(subst $\",,$(DEFAULT_CMDLINE))\"/" $(kernel_dir)/defconfig
	if [[ -f $(ST_LINUXBOOT_KERNEL_CONFIG) ]]; then \
	  if diff $(kernel_dir)/defconfig $(ST_LINUXBOOT_KERNEL_CONFIG); then \
	     echo "defconfig already up-to-date"; \
	  else \
	      echo "Move old defconfig $(notdir $(ST_LINUXBOOT_KERNEL_CONFIG)) to $(notdir $(ST_LINUXBOOT_KERNEL_CONFIG)).old"; \
	    mv $(ST_LINUXBOOT_KERNEL_CONFIG){,.old}; \
	  fi \
	fi
	rsync -c $(kernel_dir)/defconfig $(ST_LINUXBOOT_KERNEL_CONFIG); \

kernel-%: $(DOTCONFIG) $(kernel_dir)/.config
	$(MAKE) -C $(kernel_dir) $(KERNEL_MAKE_FLAGS) $*

.PHONY: all kernel kernel-%
