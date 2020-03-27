## Table of Content

| Directory                                                                                              | Description                                                    |
| ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| [`/`](../#scripts)                                                                                     | entry point                                                    |
| [`configs/`](../configs/#configs)                                                                      | configuration of operating systems                             |
| [`deploy/`](#deploy)                                                                                   | scripts and files to build firmware binaries                   |
| [`deploy/coreboot-rom/`](coreboot-rom/#deploy-coreboot-rom)                                            | (work in progress)                                             |
| [`deploy/mixed-firmware/`](mixed-firmware/#deploy-mixed-firmware)                                      | disk image solution                                            |
| [`keys/`](../keys/#keys)                                                                               | example certificates and signing keys                          |
| [`operating-system/`](../operating-system/#operating-system)                                           | folders including scripts ans files to build reprodu>          |
| [`operating-system/debian/`](../operating-system/debian/#operating-system-debian)                      | reproducible debian buster                                     |
| [`operating-system/debian/docker/`](../operating-system/debian/docker/#operating-system-debian-docker) | docker environment                                             |
| [`stboot/`](../stboot/#stboot)                                                                         | scripts and files to build stboot bootloader from source       |
| [`stboot/include/`](../stboot/include/#stboot-include)                                                 | fieles to be includes into the bootloader's initramfs          |
| [`stboot/data/`](../stboot/data/#stboot-data)                                                          | fieles to be placed on a data partition of the host            |
| [`stconfig/`](../stconfig/#stconfig)                                                                   | scripts and files to build the bootloader's configuration tool |

## Deploy

The _stboot_ boatloader can be deployed to a host in different ways. The sub directories here cover these solutions.

Generally _stboot_ is part of the host's firmware and comes as a flavor of _linuxboot_, more precisely as part of the _u-root_ initrmfs inside _linuxboot_.

See also:

- https://www.linuxboot.org/
- https://github.com/u-root/u-root
