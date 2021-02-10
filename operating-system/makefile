os := $(top)/operating-system
os-out := $(out)/operating-system
tboot-out := $(out)/tboot
tboot-cache := $(cache)/tboot
tboot-version := "v1.9.11"
tboot := $(tboot-out)/tboot.gz
tboot-url := http://hg.code.sf.net/p/tboot/code

include $(os)/debos/makefile

tboot_code := $(tboot-cache)/code/.unpack

TBOOT_CFLAGS="-Wno-error=address-of-packed-member"
gcc_version := $(shell gcc -dumpversion | cut -d . -f 1)

ifeq ($(shell [ "$(gcc_version)" -ge "9" ] && echo $$?),0)
tboot_env := CFLAGS=$(TBOOT_CFLAGS) TBOOT_CFLAGS=$(TBOOT_CFLAGS)
endif

$(tboot_code):
	mkdir -p $(tboot-cache)
	@echo [stboot] Get tboot
	hg --cwd $(tboot-cache) clone $(tboot-url)
	@echo [stboot] Update tboot to version $(tboot-version)
	hg --cwd $(dir $@) update $(tboot-version)
	touch $@

tboot $(tboot): $(tboot_code)
	@echo [stboot] Build tboot
	mkdir -p $(dir $(tboot))
	# bug: parallel build sometimes fails
	# rerun make on failiure
	$(tboot_env) ${MAKE} -C $(dir $<) dist >/dev/null 2>&1  \
		|| $(tboot_env) ${MAKE} -C $(dir $<) dist >/dev/null
	cp $(tboot-cache)/code/dist/boot/tboot.gz $(tboot)
	@echo [stboot] Done tboot

acm: $(sinit-acm-grebber_bin)
	@echo [stboot] Get ACM
	mkdir -p $(cache)/ACMs
	$(os)/get_acms.sh $(OUTREDIRECT)
	@echo [stboot] Done ACM
