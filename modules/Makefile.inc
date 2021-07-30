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

