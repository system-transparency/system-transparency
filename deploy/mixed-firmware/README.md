## Table of Content
Directory | Description
------------ | -------------
[`/`](../../README.md#scripts) | entry point
[`configs/`](../../configs/README.md#configs) | configuration of operating systems
[`deploy/`](../README.md#deploy) | scripts and files to build firmware binaries
[`deploy/coreboot-rom/`](../coreboot-rom/README.md#deploy-coreboot-rom) | (work in progress)
[`deploy/mixed-firmware/`](README.md#deploy-mixed-firmware) | disk image solution
[`keys/`](../../keys/README.md#keys) | example certificates and signing keys
[`operating-system/`](../../operating-system/README.md#operating-system) | folders including scripts ans files to build reprodu>
[`operating-system/debian/`](../../operating-system/debian/README.md#operating-system-debian) | reproducible debian buster
[`operating-system/debian/docker/`](../../operating-system/debian/docker/README.md#operating-system-debian-docker) | docker environment
[`stboot/`](../../stboot/README.md#stboot) | scripts and files to build stboot bootloader from source
[`stboot/include/`](../../stboot/include/README.md#stboot-include) | fieles to be includes into the bootloader's initramfs
[`stconfig/`](../../stconfig/README.md#stconfig) | scripts and files to build the bootloader's configuration tool from >

## Deploy Mixed-Firmware
This deployment solution can be used if no direct control over the host default firmware is given. Since the *stboot* bootloader uses the *linuxboot* architecture it consists of a Linux kernel and an initfamfs, which can be treated as a usual operating system. The approach of this solution is to create an image including this kernel and initramfs. Additionally, the image contains an active boot partition with a separate bootloader written to it. *Syslinux* is used here.

The image can then be written to the host's hard drive. During the boot process of the host's default firmware the *Syslinux* bootloader is called and hands over control to the *stboot bootloader finally.

### Scripts
#### `build_kernel.sh`
This script is invoked by 'run.sh'. It downloads and veriifys sours code for Linux kernel version 4.19.6. The kernel is build according to 'x86_64_linuxboot_config' file. This kernel will be used as part of linuxboot. The script writes 'vmlinuz-linuxboot' in this directory.

#### `create_image.sh`
This script is invoked by 'run.sh'. Firstly it creates a raw image, secondly *sfdisk* is used to write the partitions table. Thirdly the script downloads *Syslinux* bootloader and installs it to the Master Boot Record and the Partition Boot Record respectively. Finally, the *linuxboot* kernel 'vmlinuz-linuxboot' is copied to the image. The output is 'MBR_Syslinux_Linuxboot.img'.

Notice that the image is incomplete at this state. The appropriate initramfs need to be included.

#### `mount_img.sh`
This script is for custom use. If you want to inspect or modify files of 'MBR_Syslinux_Linuxboot.img' use this script. It mounts the image via a loop device at a temporary directory. The path is printed to the console.

#### `mv_hostvars_to_image.sh`
Optional at the moment. This Script copies the 'hostvars.json' configuration file to the image.

#### `mv_initrd_to_image.sh`
this script is invoked by 'run.sh'. It copies the linuxboot initramfs including *stboot* to the image.

#### `umount_img.sh`
Counterpart of 'mount_img.sh'.

### Configuration Files
#### `mbr.table`
This files describes the partition layout of the image

#### `syslinux.cfg`
This is the configuration file for *Syslinux*. The paths for kernel and initramfs are set here.

#### `x86_64_linuxboot_config`
This is the kernel config for the *linuxboot* kernel. In addition to x86_64 based *defconfig* the following is set:
```
Processor type and features  --->
    [*] Linux guest support --->
        [*] Enable Paravirtualization code
        [*] KVM Guest support (including kvmclock)
        [*] kexec file based system call
        [*] kexec jump     

Device Drivers  --->
    Virtio drivers  --->
        <*> PCI driver for virtio devices
    [*] Block devices  --->
        <*> Virtio block driver
        [*]     SCSI passthrough request for the Virtio block driver 
    Character devices  --->
        <*> Hardware Random Number Generator Core support  --->
            <*>   VirtIO Random Number Generator support
```
