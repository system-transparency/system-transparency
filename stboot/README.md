## Table of Content
Directory | Description
------------ | -------------
[`/`](../README.md#scripts) | entry point
[`configs/`](../configs/README.md#configs) | configuration of operating systems
[`deploy/`](../deploy/README.md#deploy) | scripts and files to build firmware binaries
[`deploy/coreboot-rom/`](../deploy/coreboot-rom/README.md#deploy-coreboot-rom) | (work in progress)
[`deploy/mixed-firmware/`](../deploy/mixed-firmware/README.md#deploy-mixed-firmware) | disk image solution
[`keys/`](../keys/README.md#keys) | example certificates and signing keys
[`operating-system/`](../operating-system/README.md#operating-system) | folders including scripts ans files to build reprodu>
[`operating-system/debian/`](../operating-system/debian/README.md#operating-system-debian) | reproducible debian buster
[`operating-system/debian/docker/`](../operating-system/debian/docker/README.md#operating-system-debian-docker) | docker environment
[`stboot/`](README.md#stboot) | scripts and files to build stboot bootloader from source
[`stboot/include/`](include/README.md#stboot-include) | fieles to be includes into the bootloader's initramfs
[`stconfig/`](../stconfig/README.md#stconfig) | scripts and files to build the bootloader's configuration tool from >

## Stboot
*Stboot* itself is part of the *u-root* project (https://github.com/u-root/u-root) and is written in Go. Since *Stboot* is still in a beta phase at the moment, the code resides at https://github.com/u-root/u-root/tree/stboot branch. This directory mainly provides utilities for the ongoing development.

One part of the *u-root* project is the 'u-root' command to create an initramfs (an archive of files) to use with Linux kernels. Another part is a collection of bootloaders implemented in Go. *Stboot* is one of these bootloaders.

### Scripts
#### `create_hostvars.sh`
This script is invoked by 'run.sh'. It creates an example 'hostvars.json' file. This can be used as a template for a custom 'hostvars.json'. See https://docs.system-transparency.org for further information about this configuration file.
Choose one of the following flags when calling:
* `d` : empty IP. This will trigger DHCP
* `q` : IP configuration suitable for *QEMU*

#### `install-u-root.sh`
This script is invoked by 'run.sh'. It downloads the source code for the 'u-root' command and the *Stboot* bootloader and compiles them. Further it installs a special *uinit* binary from https://github.com/system-transparency/uinit needed to call the bootloader from the initramfs' init-script.

#### `make_initrmafs.sh`
This script is invoked by 'run.sh'. It uses the 'u-root' command to build 'initramfs-linuxboot.cpio' including the *uinit* binary, the *Stboot* bootloader and further files from the 'include/' directory.
This 'initramfs-linuxboot.cpio' is the core component of each deployment solution of *System Transparency's* firmware part.

This script accepts a '-d' flag. It then includes the full set of available *Go* commands into the initfamfs to enable debugging — e.g before *uinit* hands over control to the *Stboot* bootloader or in case of a bootloader panic.
