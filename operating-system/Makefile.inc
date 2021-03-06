op := operating-system
op-out := $(out)/operating-system
tboot-out := $(out)/tboot
tboot-cache := $(cache)/tboot
tboot-version := "v1.9.11"
tboot := $(tboot-out)/tboot.gz
tboot-url := http://hg.code.sf.net/p/tboot/code
acm-dir := $(cache)/ACMs

include $(op)/debos/Makefile.inc

tboot_code := $(tboot-cache)/code/.unpack

gcc_version := $(shell gcc -dumpversion 2>/dev/null| cut -d . -f 1)

ifeq ($(shell [[ "$(gcc_version)" -ge "9" ]] && echo $$?),0)
_TBOOT_CFLAGS += -Wno-error=address-of-packed-member
endif
ifeq ($(shell [[ "$(gcc_version)" -ge "11" ]] && echo $$?),0)
_TBOOT_CFLAGS += -Wno-error=stringop-overflow
_TBOOT_CFLAGS += -Wno-error=maybe-uninitialized
_TBOOT_CFLAGS += -Wno-error=array-parameter
endif

tboot_env := CFLAGS="$(_TBOOT_CFLAGS)" TBOOT_CFLAGS="$(_TBOOT_CFLAGS)"

ifeq ($(IS_ROOT),)

$(tboot_code):
	rm -rf $(tboot-cache)
	mkdir -p $(tboot-cache)/..
	@$(call LOG,INFO,Get,$(tboot-url))
	hg --cwd $(tboot-cache) clone $(tboot-url) $(OUTREDIRECT)
	@$(call LOG,INFO,Update tboot to version,$(tboot-version))
	hg --cwd $(dir $@) update $(tboot-version) $(OUTREDIRECT)
	touch $@

tboot $(tboot): $(tboot_code)
	@$(call LOG,INFO,Build tboot)
	mkdir -p $(dir $(tboot))
	# bug: parallel build sometimes fails
	# rerun make on failiure
	$(tboot_env) ${MAKE} -C $(dir $<) dist >/dev/null 2>&1  \
		|| $(tboot_env) ${MAKE} -C $(dir $<) dist $(OUTREDIRECT)
	cp $(tboot-cache)/code/dist/boot/tboot.gz $(tboot)
	@$(call LOG,DONE,tboot:,$(tboot))

acm $(acm-dir): $(sinit-acm-grebber_bin)
	mkdir -p $(acm-dir)
	@$(call LOG,INFO,Get authenticated code modules (ACM))
	$< -of $(acm-dir)
	@$(call LOG,DONE,ACMs downloaded in:,$(acm-dir))

.PHONY: tboot acm

endif #ifeq ($(IS_ROOT),)
