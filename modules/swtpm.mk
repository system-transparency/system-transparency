swtpm_dir := $(cache)/swtpm
swtpm_src := $(swtpm_dir)/src/swtpm
libtpms_src := $(swtpm_dir)/src/libtpms

libtpms_pkg := $(swtpm_dir)/lib/pkgconfig/libtpms.pc
swtpm_bin := $(swtpm_dir)/bin/swtpm
swtpm_setup_bin := $(swtpm_dir)/bin/swtpm_setup

libtpms_version := 0.7.7
swtpm_version := 0.5.2

PYTHONPATH=$(CURDIR)/cache/swtpm/lib/python3/dist-packages

ifeq ($(IS_ROOT),)

$(tarball_dir)/libtpms-v%.tar.gz:
	mkdir -p $(tarball_dir)
	@$(call LOG,INFO,swtpm: Get,$(notdir $@))
	wget -qO $@ https://github.com/stefanberger/libtpms/archive/refs/tags/v$*.tar.gz

$(tarball_dir)/swtpm-v%.tar.gz:
	mkdir -p $(tarball_dir)
	@$(call LOG,INFO,swtpm: Get,$(notdir $@))
	wget -qO $@ https://github.com/stefanberger/swtpm/archive/refs/tags/v$*.tar.gz

$(libtpms_src)/.unpack: $(tarball_dir)/libtpms-v$(libtpms_version).tar.gz
	if [[ -d "$(dir $@)" && ! -f "$@" ]]; then \
	  rm -rf $(dir $@); \
	fi
	mkdir -p $(dir $@)
	@$(call LOG,INFO,swtpm: Unpack,$(notdir $<))
	tar xzf $< --strip 1 -C $(dir $@)
	touch $@

$(swtpm_src)/.unpack: $(tarball_dir)/swtpm-v$(swtpm_version).tar.gz
	if [[ -d "$(dir $@)" && ! -f "$@" ]]; then \
	  rm -rf $(dir $@); \
	fi
	mkdir -p $(dir $@)
	@$(call LOG,INFO,swtpm: Unpack,$(notdir $<))
	tar xzf $< --strip 1 -C $(dir $@)
	touch $@

$(libtpms_src)/Makefile: $(libtpms_src)/.unpack
	@$(call LOG,INFO,swtpm: Configure,libtpms)
	cd $(dir $@) && ./autogen.sh --with-tpm2 --with-openssl \
		--prefix="$(CURDIR)/$(swtpm_dir)" >/dev/null 2>config.log || \
	($(call LOG,ERROR,swtpm: libtpms configuration failed. See:,$(dir $@)config.log); \
	exit 1)

$(libtpms_pkg): $(libtpms_src)/Makefile
	@$(call LOG,INFO,swtpm: Make,libtpms)
	$(MAKE) -C $(dir $<) install >/dev/null 2>$(dir $<)build.log || \
	($(call LOG,ERROR,swtpm: libtpms build failed. See:,$(dir $<)build.log); \
	exit 1)
	@$(call LOG,DONE,swtpm:,libtpms)

$(swtpm_src)/Makefile: $(libtpms_pkg) $(swtpm_src)/.unpack
	@$(call LOG,INFO,swtpm: Configure,swtpm)
	cd $(dir $@) && PKG_CONFIG_PATH="$(CURDIR)/$(dir $<)" \
	        ./autogen.sh --prefix="$(CURDIR)/$(swtpm_dir)" >/dev/null 2>config.log || \
	($(call LOG,ERROR,swtpm: swtpm configuration failed. See:,$(dir $@)config.log); \
	exit 1)

$(swtpm_bin): $(swtpm_src)/Makefile
	mkdir -p $(dir $@)
	@$(call LOG,INFO,swtpm: Make,swtpm)
	$(MAKE) -C $(dir $<) python-install install >/dev/null 2>$(dir $<)build.log || \
	($(call LOG,ERROR,swtpm: swtpm build failed. See,$(dir $<)build.log); \
	exit 1)
	@$(call LOG,DONE,swtpm:,$(swtpm_bin))

swtpm: $(swtpm_bin)

.PHONY: swtpm

endif #ifeq ($(IS_ROOT),)
