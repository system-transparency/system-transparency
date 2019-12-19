## Table of Content
Directory | Description
------------ | -------------
[`/`](../README.md#scripts) | entry point
[`configs/`](../configs/README.md#configs) | configuration of operating systems
[`deploy/`](../deploy/README.md#deploy) | scripts and files to build firmware binaries
[`deploy/coreboot-rom/`](../deploy/coreboot-rom/README.md#deploy-coreboot-rom) | (work in progress)
[`deploy/mixed-firmware/`](../deploy/mixed-firmware/README.md#deploy-mixed-firmware) | disk image solution
[`keys/`](README.md#keys) | example certificates and signing keys
[`operating-system/`](../operating-system/README.md#operating-system) | folders including scripts ans files to build reprodu>
[`operating-system/debian/`](../operating-system/debian/README.md#operating-system-debian) | reproducible debian buster
[`operating-system/debian/docker/`](../operating-system/debian/docker/README.md#operating-system-debian-docker) | docker environment
[`stboot/`](../stboot/README.md#stboot) | scripts and files to build stboot bootloader from source
[`stboot/include/`](../stboot/include/README.md#stboot-include) | fieles to be includes into the bootloader's initramfs
[`stconfig/`](../stconfig/README.md#stconfig) | scripts and files to build the bootloader's configuration tool from >

## Keys
This directory contains example data only.

### Scripts
#### `generate_keys_and_certs.sh`
This script is invoked by `run.sh`. It generates certificate authority (CA), a self signed root certificate and a set of 5 signing keys, certified by the CA.
