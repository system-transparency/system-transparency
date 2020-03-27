## Table of Content

| Directory                                                                                              | Description                                                    |
| ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| [`/`](../#scripts)                                                                                     | entry point                                                    |
| [`configs/`](../configs/#configs)                                                                      | configuration of operating systems                             |
| [`deploy/`](../deploy/#deploy)                                                                         | scripts and files to build firmware binaries                   |
| [`deploy/coreboot-rom/`](../deploy/coreboot-rom/#deploy-coreboot-rom)                                  | (work in progress)                                             |
| [`deploy/mixed-firmware/`](../deploy/mixed-firmware/#deploy-mixed-firmware)                            | disk image solution                                            |
| [`keys/`](../keys/#keys)                                                                               | example certificates and signing keys                          |
| [`operating-system/`](../operating-system/#operating-system)                                           | folders including scripts ans files to build reprodu>          |
| [`operating-system/debian/`](../operating-system/debian/#operating-system-debian)                      | reproducible debian buster                                     |
| [`operating-system/debian/docker/`](../operating-system/debian/docker/#operating-system-debian-docker) | docker environment                                             |
| [`stboot/`](#stboot)                                                                                   | scripts and files to build stboot bootloader from source       |
| [`stboot/include/`](include/#stboot-include)                                                           | fieles to be includes into the bootloader's initramfs          |
| [`stboot/data/`](data/#stboot-data)                                                                    | fieles to be placed on a data partition of the host            |
| [`stconfig/`](../stconfig/#stconfig)                                                                   | scripts and files to build the bootloader's configuration tool |

## Stboot

_Stboot_ itself is part of the _u-root_ project (https://github.com/u-root/u-root) and is written in Go. Since _Stboot_ is still in a beta phase at the moment, the code resides at https://github.com/u-root/u-root/tree/stboot branch. This directory mainly provides utilities for the ongoing development.

One part of the _u-root_ project is the 'u-root' command to create an initramfs (an archive of files) to use with Linux kernels. Another part is a collection of bootloaders implemented in Go. _Stboot_ is one of these bootloaders.

### Scripts

#### `create_hostvars.sh`

This script is invoked by 'run.sh'. It creates an example 'hostvars.json' file. This can be used as a template for a custom 'hostvars.json'. See https://system-transparency.org for further information about this configuration file.
Choose one of the following flags when calling:

- `d` : empty IP. This will trigger DHCP
- `q` : IP configuration suitable for _QEMU_

#### `install_u-root.sh`

This script is invoked by 'run.sh'. It downloads the source code for the 'u-root' command and the _Stboot_ bootloader and compiles them. Further it installs a special _uinit_ binary from https://github.com/system-transparency/uinit needed to call the bootloader from the initramfs' init-script.

#### `make_initrmafs.sh`

This script is invoked by 'run.sh'. It uses the 'u-root' command to build 'initramfs-linuxboot.cpio' including the _uinit_ binary, the _Stboot_ bootloader and further files from the 'include/' directory.
This 'initramfs-linuxboot.cpio' is the core component of each deployment solution of _System Transparency's_ firmware part.

This script accepts a '-d' flag. It then includes the full set of available _Go_ commands into the initfamfs to enable debugging — e.g before _uinit_ hands over control to the _Stboot_ bootloader or in case of a bootloader panic.
