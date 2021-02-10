os := $(top)/operating-system
os-out := $(out)/operating-system/

include $(os)/debos/makefile

tboot $(tboot):
	@echo [stboot] Build tboot
	$(os)/build_tboot.sh MAKE=$(MAKE) $(OUTREDIRECT)
	@echo [stboot] Done tboot

acm: $(sinit-acm-grebber_bin)
	@echo [stboot] Get ACM
	mkdir -p $(cache)/ACMs
	$(os)/get_acms.sh $(OUTREDIRECT)
	@echo [stboot] Done ACM
