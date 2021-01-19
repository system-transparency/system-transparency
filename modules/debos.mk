debos-image := debos-debian
debos-tag := system-transparency

docker-check:
	@echo [debos] Check docker API access
	if !(docker info >/dev/null 2>&1); then \
	  echo "[debos] Error: no access to docker API"; \
	  exit 1; \
	fi

debos: debos-debian debos-ubuntu

debos-debian: docker-check
	@echo "[debos] Build docker image for Debian OS";
	docker build --network=host -q -t $(debos-image):$(debos-tag) $(top)/operating-system/debian;
	@echo "[debos] Using docker image "$(shell docker images -q $(debos-image):$(debos-tag))" for building Debian OS";

debos-ubuntu: docker-check
	@echo "[debos] Build docker image for Ubuntu OS";
	docker build --network=host -q -t $(debos-image):$(debos-tag) $(top)/operating-system/ubuntu;
	@echo "[debos] Using docker image "$(shell docker images -q $(debos-image):$(debos-tag))" for building Ubuntu OS";

.PHONY: debos debos-ubuntu debos-debian docker-check
