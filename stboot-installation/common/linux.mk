kernel := $(st-out)/linuxboot.vmlinuz
gpg_dir := $(cache)/gnupg
gpg_keyring := $(gpg_dir)/keyring.gpg
kernel_mirror := https://cdn.kernel.org/pub/linux/kernel
kernel_image := arch/x86/boot/bzImage
kernel_dev_1 := torvalds@kernel.org
kernel_dev_2 := gregkh@kernel.org

KERNEL_MAKE_FLAGS := ARCH=x86_64
DEFAULT_CMDLINE="console=ttyS0,115200"
# escape backslash
ifneq ($(strip $(wildcard $(DOTCONFIG))),)
_ST_LINUXBOOT_CMDLINE := $(shell echo '$(ST_LINUXBOOT_CMDLINE)' | sed 's/\\/\\\\/g')
endif

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
kernel_dir := $(cache)/linux/kernel-$(subst .,_,$(kernel_version))
kernel_target := $(kernel_dir)/$(kernel_image)

kernel: $(kernel)

$(eval $(call CONFIG_DEP,$(kernel),ST_LINUXBOOT_KERNEL_CONFIG|ST_LINUXBOOT_KERNEL_VERSION|ST_LINUXBOOT_CMDLINE))
$(kernel): % : $(kernel_target) %.config
	mkdir -p $(dir $@)
	cp $< $@
	$(call LOG,DONE,Linux: kernel,$(kernel_version))

$(gpg_keyring):
	mkdir -p -m 700 "$(gpg_dir)"
	@$(call LOG,INFO,Linux: Fetch kernel developer keys)
	gpg -q --batch --homedir "$(gpg_dir)" --auto-key-locate wkd --locate-keys $(kernel_dev_1) $(kernel_dev_2) $(OUTREDIRECT)
	gpg -q --batch --homedir "$(gpg_dir)" --no-default-keyring --export $(kernel_dev_1) $(kernel_dev_2) > $(gpg_keyring)

# fetch linux tarball
$(tarball_dir)/linux-%.tar.xz:
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	mkdir -p $(tarball_dir)
	@$(call LOG,INFO,Linux: Get,$($*_kernel_tarball))
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	wget -qP $(tarball_dir) $($*_kernel_mirror_path)/$($*_kernel_tarball)

# fetch linux tarball signature
$(tarball_dir)/linux-%.tar.sign:
	$(eval $*_kernel_sign := linux-$*.tar.sign)
	mkdir -p $(tarball_dir)
	@$(call LOG,INFO,Linux: Get,$($*_kernel_sign))
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	wget -qP $(tarball_dir) $($*_kernel_mirror_path)/$($*_kernel_sign)

# TODO: verify sha256sum signature
# fetch linux tarball sha256
$(tarball_dir)/linux-%.tar.asc:
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	$(eval $*_kernel_sha := linux-$*.tar.asc)
	mkdir -p $(tarball_dir)
	@$(call LOG,INFO,Linux: Get,$($*_kernel_sha))
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	wget -qP $(tarball_dir) -O - $($*_kernel_mirror_path)/sha256sums.asc \
		| grep "$($*_kernel_tarball)" > $@

# check linux tarball sha256sum
$(tarball_dir)/linux-%.tar.checksum: $(tarball_dir)/linux-%.tar.xz $(tarball_dir)/linux-%.tar.asc
	$(eval $(call KERNEL_MIRROR_PATH,$*))
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	$(eval $*_kernel_sha := linux-$*.tar.asc)
	@$(call LOG,INFO,Linux: Check sha256,$($*_kernel_tarball))
	if ! (cd $(tarball_dir) && sha256sum -c $($*_kernel_sha)); then \
	  $(call LOG,ERROR,Linux: sha256 missmatch,$($*_kernel_tarball)); \
	  $(call LOG,INFO,Linux: Moving $($*_kernel_tarball) to .invalid.$($*_kernel_tarball)); \
	  mv $(tarball_dir)/$($*_kernel_tarball) $(tarball_dir)/.invalid.$($*_kernel_tarball); \
	  $(call LOG,INFO,Linux: Rerun to download,$($*_kernel_tarball)); \
	  exit 1; \
	fi
	touch $@

# verify linux tarball
$(tarball_dir)/linux-%.tar.xz.valid: $(tarball_dir)/linux-%.tar.xz $(tarball_dir)/linux-%.tar.sign $(tarball_dir)/linux-%.tar.checksum $(gpg_keyring)
	$(eval $*_kernel_tarball := linux-$*.tar.xz)
	$(eval $*_kernel_sign := linux-$*.tar.sign)
	if ! xz -t $(tarball_dir)/$($*_kernel_tarball); then \
	  $(call LOG,ERROR,Linux: Bad integrity,$($*_kernel_tarball)); \
	  exit 1; \
	fi
	@$(call LOG,INFO,Linux: Verify,$($*_kernel_tarball))
	if [[ "`xz -cd $(tarball_dir)/$($*_kernel_tarball) | \
	  gpgv -q --homedir "$(gpg_dir)" "--keyring=$(gpg_keyring)" --status-fd=1 $(tarball_dir)/$($*_kernel_sign) - | \
	  grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)';`" -lt 2 ]]; then \
	  $(call LOG,ERROR,Linux: Verification failed:,$($*_kernel_tarball)); \
	  exit 1; \
	else \
	  $(call LOG,INFO,Linux: Verification successful:,$($*_kernel_tarball)); \
	fi;
	touch $@

$(kernel_target): $(kernel_dir)/.config  $(initramfs)
	$(call LOG,INFO,Linux: Make kernel,$(kernel_version))
	$(MAKE) -C $(kernel_dir) $(KERNEL_MAKE_FLAGS) bzImage
	touch $@

$(kernel_dir)/.config: $(DOTCONFIG) $(kernel_dir)/.unpack $(patsubst "%",%,$(ST_LINUXBOOT_KERNEL_CONFIG))
	$(call LOG,INFO,Linux: Configure kernel,$(kernel_version));
ifneq ($(strip $(ST_LINUXBOOT_KERNEL_CONFIG)),)
	$(call LOG,INFO,Linux: Use configuration file,$(patsubst "%",%,$(ST_LINUXBOOT_KERNEL_CONFIG)));
	cp $(ST_LINUXBOOT_KERNEL_CONFIG) $@.tmp
ifneq ($(strip $(ST_LINUXBOOT_CMDLINE)),)
	$(call LOG,WARN,Linux: Override CONFIG_CMDLINE with ST_LINUXBOOT_CMDLINE=$(_ST_LINUXBOOT_CMDLINE));
	sed -ie 's/CONFIG_CMDLINE=.*/CONFIG_CMDLINE=$(_ST_LINUXBOOT_CMDLINE)/g' $@.tmp
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
	$(call LOG,INFO,Linux: Unpack $(kernel_tarball)); \
	tar xJf $(tarball_dir)/$(kernel_tarball) --strip 1 -C $(kernel_dir); \
	fi
	touch $@

kernel-updatedefconfig: $(kernel_dir)/.config $(DOTCONFIG)
	$(call LOG,INFO,Linux: Update defconfig $(ST_LINUXBOOT_KERNEL_CONFIG))
	$(MAKE) -C $(kernel_dir) $(KERNEL_MAKE_FLAGS) savedefconfig
	sed -ie "s/CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"$(subst $\",,$(DEFAULT_CMDLINE))\"/" $(kernel_dir)/defconfig
	if [[ -f $(ST_LINUXBOOT_KERNEL_CONFIG) ]]; then \
	  if diff $(kernel_dir)/defconfig $(ST_LINUXBOOT_KERNEL_CONFIG) $(OUTREDIRECT); then \
	    $(call LOG,WARN,Linux: defconfig already up-to-date); \
          else \
	    $(call LOG,INFO,Linux: Move old defconfig $(notdir $(ST_LINUXBOOT_KERNEL_CONFIG)) to $(notdir $(ST_LINUXBOOT_KERNEL_CONFIG)).old); \
	    mv $(ST_LINUXBOOT_KERNEL_CONFIG){,.old}; \
	  fi \
	fi
	rsync -c $(kernel_dir)/defconfig $(ST_LINUXBOOT_KERNEL_CONFIG); \

kernel-%: $(DOTCONFIG) $(kernel_dir)/.config
	$(MAKE) -C $(kernel_dir) $(KERNEL_MAKE_FLAGS) $*

.PHONY: kernel kernel-%
