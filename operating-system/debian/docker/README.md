## Table of Content
Directory | Description
------------ | -------------
[`/`](../../../README.md#scripts) | entry point
[`configs/`](../../../configs/README.md#configs) | configuration of operating systems
[`deploy/`](../../../deploy/README.md#deploy) | scripts and files to build firmware binaries
[`deploy/coreboot-rom/`](../../../deploy/coreboot-rom/README.md#deploy-coreboot-rom) | (work in progress)
[`deploy/mixed-firmware/`](../../../deploy/mixed-firmware/README.md#deploy-mixed-firmware) | disk image solution
[`keys/`](../../../keys/README.md#keys) | example certificates and signing keys
[`operating-system/`](../../README.md#operating-system) | folders including scripts ans files to build reprodu>
[`operating-system/debian/`](../README.md#operating-system-debian) | reproducible debian buster
[`operating-system/debian/docker/`](README.md#operating-system-debian-docker) | docker environment
[`stboot/`](../../../stboot/README.md#stboot) | scripts and files to build stboot bootloader from source
[`stboot/include/`](../../../stboot/include/README.md#stboot-include) | fieles to be includes into the bootloader's initramfs
[`stboot/data/`](../../../stboot/data/README.md#stboot-data) | fieles to be placed on a data partition of the host
[`stconfig/`](../../../stconfig/README.md#stconfig) | scripts and files to build the bootloader's configuration tool

## Operating-System Debian Docker
todo: intro

### Scripts
#### `build_debian.sh`
Invoked by `run.sh`. Todo...

#### `pack-reproducible.sh`
Part of *Debian* build process in *Docker*

#### `run-in-chroot.sh`
Part of *Debian* build process in *Docker*

### Configuration Files
#### `debootstrap-buster.patch`
todo ...

#### `debos.yaml`
todo ...

#### `Dockerfile`
todo ...

### Directories
#### `out/`
Built directory. The compiled kernel and initramfs are stored here.

#### `overlays/`
todo ...

