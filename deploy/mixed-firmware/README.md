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




linux kernel config

In addition to x86_64 based defconfig:
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
