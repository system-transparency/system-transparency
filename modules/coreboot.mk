tarball_dir := $(cache)/tarball
cb_gpg_dir := $(cache)/gnupg/coreboot
cb_gpg_keyring := $(cb_gpg_dir)/keyring.gpg
cb_mirror := https://coreboot.org/releases
cb_dev := martin@coreboot.org

cb_dir := $(cache)/coreboot
cbfstool := $(cache)/bin/cbfstool


CPUS=$(shell nproc)

$(cb_gpg_keyring):
	mkdir -p -m 700 "$(cb_gpg_dir)"
	echo "[coreboot] Fetch coreboot developer key"
	gpg -q --batch --homedir "$(cb_gpg_dir)" --keyserver pgp.mit.edu --auto-key-locate wkd --locate-keys $(cb_dev) $(OUTREDIRECT)
	gpg -q --batch --homedir "$(cb_gpg_dir)" --no-default-keyring --export $(cb_dev) > $@

# fetch coreboot tarball and signatures
$(tarball_dir)/coreboot-%.tar.xz $(tarball_dir)/coreboot-%.tar.xz.sig:
	mkdir -p $(tarball_dir)
	@echo "[coreboot] Get $(notdir $@)"
	cd $(tarball_dir) && curl -OLSs $(cb_mirror)/$(notdir $@)

# prevent deletion

$(cb_dir)/coreboot-%/.unpack: $(tarball_dir)/coreboot-%.tar.xz
	@echo "[coreboot] Unpack $(notdir $<)"
	if [[ -d "$(dir $@)" && ! -f "$@" ]]; then \
	rm -rf $(dir $@); \
	fi
	mkdir -p $(dir $@)
	tar xJf $< --strip 1 -C $(dir $@)
	touch $@

$(cb_dir)/coreboot-%/.xcompile: $(cb_dir)/coreboot-%/.unpack
	@echo "[coreboot] Build crossgcc-i386"
	$(MAKE) -C $(dir $@) CPUS=$(CPUS) crossgcc-i386
	@echo "[coreboot] Done crossgcc-i386"
	touch $@

.PRECIOUS: $(tarball_dir)/coreboot-%.tar.xz $(tarball_dir)/coreboot-%.tar.xz.sig $(cb_dir)/coreboot-%/.unpack $(cb_dir)/coreboot-%/.xcompile

$(cb_dir)/coreboot-%/util/cbfstool/cbfstool: $(cb_dir)/coreboot-%/.unpack
	@echo "[coreboot] Build $(notdir $@)"
	$(MAKE) -C $(dir $@)
	@echo "[coreboot] done $(notdir $@)"

$(cbfstool): $(cb_dir)/coreboot-4.13/util/cbfstool/cbfstool
	mkdir -p $(dir  $@)
	rsync -c $< $@

# verify coreboot tarball
#$(tarball_dir)/coreboot-%.tar.xz.valid:  $(tarball_dir)/coreboot-%.tar.xz $(tarball_dir)/coreboot-%.tar.xz.sig $(cb_gpg_keyring)
#	$(eval $*_cb_tarball := coreboot-$*.tar.xz)
#	$(eval $*_cb_sign := coreboot-$*.tar.sign)
#	if ! xz -t $(tarball_dir)/$($*_cb_tarball); then \
#	  echo [coreboot] Bad integrity $($*_cb_tarball); \
#	  exit 1; \
#	fi
#	@echo "[coreboot] Verify $($*_cb_tarball)"
#	if [[ "`xz -cd $(tarball_dir)/$($*_cb_tarball) | \
#		gpgv -q --homedir "$(cb_gpg_dir)" "--keyring=$(cb_gpg_keyring)" --status-fd=1 $(tarball_dir)/$($*_cb_sign) - | \
#		grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)';`" -lt 1 ]]; then \
#	  echo "[coreboot] Verification of $($*_cb_tarball) failed"; \
#	  exit 1; \
#	else \
#	  echo "[coreboot] Verification of $($*_cb_tarball) successful"; \
#	fi;
#	touch $@
