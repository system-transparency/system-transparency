## Table of Content
Directory | Description
------------ | -------------
[`/`](../README.md#scripts) | entry point
[`configs/`](README.md#configs) | configuration of operating systems
[`deploy/`](../deploy/README.md#deploy) | scripts and files to build firmware binaries
[`deploy/coreboot-rom/`](../deploy/coreboot-rom/README.md#deploy-coreboot-rom) | (work in progress)
[`deploy/mixed-firmware/`](../deploy/mixed-firmware/README.md#deploy-mixed-firmware) | disk image solution
[`keys/`](../keys/README.md#keys) | example certificates and signing keys
[`operating-system/`](../operating-system/README.md#operating-system) | folders including scripts ans files to build reprodu>
[`operating-system/debian/`](../operating-system/debian/README.md#operating-system-debian) | reproducible debian buster
[`operating-system/debian/docker/`](../operating-system/debian/docker/README.md#operating-system-debian-docker) | docker environment
[`stboot/`](../stboot/README.md#stboot) | scripts and files to build stboot bootloader from source
[`stboot/include/`](../stboot/include/README.md#stboot-include) | fieles to be includes into the bootloader's initramfs
[`stboot/data/`](../stboot/data/README.md#stboot-data) | fieles to be placed on a data partition of the host
[`stconfig/`](../stconfig/README.md#stconfig) | scripts and files to build the bootloader's configuration tool

## Configs
Directories for individual operating-system configuration can be created here. These directories must at least contain a 'stconfig.json' file. The corresponding files like OS-kernel, OS-initramfs, etc. can be included as well. After utilizing the *stconfig tool* 'stboot.ball' is saved there as well.
See http://doc.system-transparency.org for further information about 'stconfig.json' and 'stboot.ball'

The *debian* system included in this repository will create its configuration directory here automatically during the setup.
