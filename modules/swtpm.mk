swtpm_dir := $(cache)/swtpm
swtpm_src := $(swtpm_dir)/src/swtpm
libtpms_src := $(swtpm_dir)/src/libtpms

libtpms_pkg := $(swtpm_dir)/lib/pkgconfig/libtpms.pc
swtpm_bin := $(swtpm_dir)/bin/swtpm
swtpm_setup_bin := $(swtpm_dir)/bin/swtpm_setup

libtpms_version := 0.7.7
swtpm_version := 0.5.2

$(tarball_dir)/libtpms-v%.tar.gz:
	mkdir -p $(tarball_dir)
	@$(call LOG,INFO,Get,$(notdir $@))
	wget -qO $@ https://github.com/stefanberger/libtpms/archive/refs/tags/v$*.tar.gz

$(tarball_dir)/swtpm-v%.tar.gz:
	mkdir -p $(tarball_dir)
	@$(call LOG,INFO,Get,$(notdir $@))
	wget -qO $@ https://github.com/stefanberger/swtpm/archive/refs/tags/v$*.tar.gz

$(libtpms_src)/.unpack: $(tarball_dir)/libtpms-v$(libtpms_version).tar.gz
	if [[ -d "$(dir $@)" && ! -f "$@" ]]; then \
	  rm -rf $(dir $@); \
	fi
	mkdir -p $(dir $@)
	@$(call LOG,INFO,Unpack,$(notdir $<))
	tar xzf $< --strip 1 -C $(dir $@)
	touch $@

$(swtpm_src)/.unpack: $(tarball_dir)/swtpm-v$(swtpm_version).tar.gz
	if [[ -d "$(dir $@)" && ! -f "$@" ]]; then \
	  rm -rf $(dir $@); \
	fi
	mkdir -p $(dir $@)
	@$(call LOG,INFO,Unpack,$(notdir $<))
	tar xzf $< --strip 1 -C $(dir $@)
	touch $@

$(libtpms_src)/Makefile: $(libtpms_src)/.unpack
	@$(call LOG,INFO,Autogenerate libtpms configuration)
	cd $(dir $@) && ./autogen.sh --with-tpm2 --with-openssl \
		--prefix="$(CURDIR)/$(swtpm_dir)" $(OUTREDIRECT)

$(libtpms_pkg): $(libtpms_src)/Makefile
	@$(call LOG,INFO,Make,libtpms)
	$(MAKE) -C $(dir $<) install
	@$(call LOG,DONE,libtpms)

$(swtpm_src)/Makefile: $(libtpms_pkg) $(swtpm_src)/.unpack
	@$(call LOG,INFO,Autogenerate swtpm configuration)
	cd $(dir $@) && PKG_CONFIG_PATH="$(CURDIR)/$(dir $<)" \
	        ./autogen.sh --prefix="$(CURDIR)/$(swtpm_dir)" $(OUTREDIRECT)

$(swtpm_bin): $(swtpm_src)/Makefile
	mkdir -p $(dir $@)
	@$(call LOG,INFO,Make,swtpm)
	$(MAKE) -C $(dir $<) install
	@$(call LOG,DONE,$(swtpm_bin))

swtpm: $(swtpm_bin)

.PHONY: swtpm
