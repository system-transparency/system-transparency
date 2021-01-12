build ?= $(CURDIR)/build
top ?= $(CURDIR)
image := debos-debian
tag := system-transparency

all: debian ubuntu

check:
	@echo [debos] Check docker API acces
	if !(docker info >/dev/null 2>&1); then \
	  echo "[debos] Error: no access to docker API"; \
	  exit 1; \
	fi

debian: check
	@echo "[debos] Build docker image for Debian OS";
	docker build --network=host -q -t $(image):$(tag) $(top)/operating-system/debian;
	@echo "[debos] Using docker image "$(shell docker images -q $(image):$(tag))" for building Debian OS";

ubuntu: check
	@echo "[debos] Build docker image for Ubuntu OS";
	docker build --network=host -q -t $(image):$(tag) $(top)/operating-system/ubuntu;
	@echo "[debos] Using docker image "$(shell docker images -q $(image):$(tag))" for building Ubuntu OS";

.PHONY: all ubuntu debian check
