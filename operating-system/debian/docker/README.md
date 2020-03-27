## Table of Content

| Directory                                                                         | Description                                                    |
| --------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| [`/`](../../../#scripts)                                                          | entry point                                                    |
| [`configs/`](../../../configs/#configs)                                           | configuration of operating systems                             |
| [`deploy/`](../../../deploy/#deploy)                                              | scripts and files to build firmware binaries                   |
| [`deploy/coreboot-rom/`](../../../deploy/coreboot-rom/#deploy-coreboot-rom)       | (work in progress)                                             |
| [`deploy/mixed-firmware/`](../../../deploy/mixed-firmware/#deploy-mixed-firmware) | disk image solution                                            |
| [`keys/`](../../../keys/#keys)                                                    | example certificates and signing keys                          |
| [`operating-system/`](../../#operating-system)                                    | folders including scripts ans files to build reprodu>          |
| [`operating-system/debian/`](../#operating-system-debian)                         | reproducible debian buster                                     |
| [`operating-system/debian/docker/`](#operating-system-debian-docker)              | docker environment                                             |
| [`stboot/`](../../../stboot/#stboot)                                              | scripts and files to build stboot bootloader from source       |
| [`stboot/include/`](../../../stboot/include/#stboot-include)                      | fieles to be includes into the bootloader's initramfs          |
| [`stboot/data/`](../../../stboot/data/#stboot-data)                               | fieles to be placed on a data partition of the host            |
| [`stconfig/`](../../../stconfig/#stconfig)                                        | scripts and files to build the bootloader's configuration tool |

## Operating-System Debian Docker

todo: intro

### Scripts

#### `build_debian.sh`

Invoked by `run.sh`. Todo...

#### `pack-reproducible.sh`

Part of _Debian_ build process in _Docker_

#### `run-in-chroot.sh`

Part of _Debian_ build process in _Docker_

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
