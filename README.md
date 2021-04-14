# System Transparency Tooling

This repository contains tooling, configuration files and example data to form a build-, test- and development environment for _System Transparency_.

_stboot_ is System Transparency Project’s official bootloader. It is a LinuxBoot distribution based on u-root.
A LinuxBoot distribution is simply a Linux kernel and an initramfs. U-root is another project consisting of an initramfs builder, a collection of core Linux commands implemented in Go, and a collection of bootloaders. stboot is one of these bootloaders. Source code of stboot: https://github.com/u-root/u-root/tree/stboot

The stboot program embedded in the initramfs acts as a bootloader to find the real OS - kernel and userland - for the host. The OS comes with one or more signatures to prove its validity. Furthermore, it supports Intel®'s Trusted Execution Technology (TXT) by booting the OS via tboot. All OS related artifacts are bundled together in an _OS Package_. An OS package consists of an archive file (ZIP) and descriptor file (JSON). OS packages can be created and managed with the _stmanager_ tool. Source code of stmanager: https://github.com/u-root/u-root/tree/stboot/tools/stmanager


stboot currently supports loading the OS packages from an HTTP/HTTPS server or from local storage.


# Prerequisites

* The operator machine should run a Linux system (tested with Ubuntu 18.04.2 LTS (Bionic Beaver) / Kernel 4.15.0-47-generic

# Installation

## Setup
```bash
# Check for missing dependencies
make check
# make default configuration
make config
# modify configuration
${EDITOR} run.config
# build toolchain (u-root et al.)
make toolchain

```
## OS Package
To create an example OS package to get started with just do:
```bash
# Generate sign keys
make keygen-sign
# build configures OS kernel and initramfs, create and signs an OS package
make sign
```

Otherwise, to build a custom OS package use stmanager directly. Therefore, you need a kernel & initramfs which contains the complete userspace. Use one of the following or create your own. The following commands create OS kernel & initramfs using _debos_. If debos cannot be run native on your system, virtualization options will be used:
``` bash
# Build debian system described in operating-system/debos/debian.yaml
make debian
# Build ubuntu system described in operating-system/debos/ubuntu.yaml
make ubuntu-18                    
make ubuntu-20                    
```

Once you have an OS kernel & initramfs containing the usersapce and optionally a tboot kernel and appropriate ACM for TXT create an OS package out of it:
``` bash
# Create a new OS package
./cache/go/bin/stmanager create --kernel=KERNEL --initramfs=INITRAMFS
# Sign the OS package (multiple times)
./cache/go/bin/stmanager sign --key=KEY --cert=CERT <OS package>

# See help for all options
./cache/go/bin/stmanager --help-long

```

## stboot image
``` bash
# Build all available installation options
make
```
Otherwise, use one of the following dedicated options.
Regarding deployment, we defined three real world scenarios which should at least support a high chance that we have covered a lot of hardware systems.

### Leased server with MBR bootloader installation
Bringing system transparency to already existing hardware which can’t be transformed to open source firmware machines is troublesome. Therefore, we need to propose a solution which even works on those limited systems. This scenario is especially helpful for a server landscape with mixed firmware like BIOS and UEFI.

```bash
make mbr-bootloader-installation
```

### Leased server with EFI application installation
In this scenario we have a closed source UEFI firmware which cannot easily be modified. In order to deploy _stboot_ underneath, we will use the Linux EFI stub kernel feature and compile the kernel as an EFI application.

```bash
make efi-application-installation
```

### Colocated server with coreboot payload installation
In this scenario we can place our own server in the data center. This server already contains Open Source firmware and is able to boot a Linux kernel payload after hardware initialization.

```
# Work in Progress: Not yet implemented!
#make coreboot-payload-installation
```

To build and flash the coreboot-rom including _stboot_ as a payload, please refer to [these instructions](stboot-installation/coreboot-payload/#deploy-coreboot-rom). 


# Test Your Installation
``` bash 
# run MBR bootloader installation
make run-mbr-bootloader
# run EFI application installation
make run-efi-application
```

# Deployment
The bootloader artifact can be built in three different formats:

## MBR Bootloader Installation
When built as an MBR bootloader there is one artefact `out/stboot-installation/mbr-bootloader/stboot_mbr_installation.img`containing:
* SYSLINUX (for the Master Boot Record)
* A VFAT/FAT32 partition named STBOOT containing:
    * Syslinux configuration
    * LinuxBoot files
    * Less critical configuration data (host_configuration.json for stboot.
* An Ext4 partition named STDATA containing
    * An OS package if boot method is set to _local_.
    * An empty directory for use as a cache if the boot method is set to _network_.

You need to write this image to the hard drive of the host.

## EFI Application Installation
When built as an EFI application there is one artefact `out/stboot-installation/efi-application/stboot_efi_installation.img` containing:
* A VFAT/FAT32 partition named STBOOT marked as an EFI system partition containing:
    * LinuxBoot files compiled as an EFI stub
    * Less critical configuration data (host_configuration.json) for stboot.
*An Ext4 partition named STDATA containing:
    * An OS package if boot method is set to _local_.
    * An empty directory for use as a cache if the boot method is set to _network_.

You need to write this image to the hard drive of the host.

## coreboot Payload Installation
_WORK IN PROGRESS_

When built as a coreboot payload there will be two artifacts:
* A file named coreboot.rom containing an SPI flash image.
* A file named stboot_coreboot_installation.img containing:
    * A VFAT/FAT32 partition named STBOOT containing:
        * Less critical configuration data (host_configuration.json) for stboot.
    * An Ext4 partition named STDATA containing:
        * An OS package if boot method is set to _local_.
        * An empty directory for use as a cache if boot method is set to _network_.

You need to write the coreboot.rom to the SPI Flash of the host and write the image to the hard drive of the host.

# System Configuration

## Configuration of stboot
Most options can be set in `run.config`. See the descriptions there for details.

A subset of the configuration options in `run.config` end up in two files which stboot reads in during the boot process:

### host_configuration.json
This file is written to the root directory of the STBOOT partition. It contains the following fields:
``` json
version:
network_mode: “dhcp” XOR “static”
host_ip:"",
gateway:"",
dns:""
provisioning_urls: [list of urls]
identity: identity (hex-encoded 256-bit entropy)
authentication: shared_secret (hex-encoded 256-bit entropy)
entropy_seed: seed (hex-encoded 256-bit entropy)
```

### security_configuration.json
This file is compiled into the LinuxBoot initramfs at `/etc/security_configuration.json`. It contains the following security critical fields:
``` json
version: ,
min_valid_sigs_required: ,
build_timestamp: 1602108426,
boot_mode: "local" XOR “network”
use_ospkg_cache: false XOR false

```

## Modify LinuxBoot kernel config
```bash
# Run MBR bootloader kernel menuconfig
make mbr-kernel-menuconfig
# Update MBR bootloader kernel defconfig
make mbr-kernel-updatedefconfig
```

# Features

stboot extensively validates the state of the system and all data it will use in its control flow. In case of any error it will reboot the system. At the end of the control flow stboot will use kexec to hand over the control to the kernel provided in the OS package. From that point on stboot has no longer control over the system.

## System Time Validation
A proper system time is important for validating certificates. It is the responsibility of the operator to set the system time correctly. However, stboot performs the following check:

* Look at the system time, look at the timestamp on `STDATA/stboot/etc/system_time_fix`
* Set system time to the latest.

The OS is allowed to update this file. Especially if it’s an embedded system without a RTC.

## Boot Methods
stboot supports two boot methods - Network and Local. Network loads an OS package from a provisioning server. Local loads an OS package from the STDATA partition on a local disk. Only one boot method at a time may be configured.

### Network boot
Network boot can be configured using either DHCP or a static network configuration. In case of static network stboot uses IP address, netmask, default gateway, and DNS server from `host_configuration.json`. The latest downloaded and verified OS package can be cached depending on settings in `security_configuration.json`. Older ones are removed. The cache directory is separate from the directory used by the Local boot method.

Provisioning Server Communication:
* The HTTPS root certificates are stored in the LinuxBoot initramfs
    * File name: `/etc/https_roots.pem`
    * Use https://letsencrypt.org/certificates/ roots as default.
Regarding Provisioning URLs:
* If multiple provisioning URLs are present in host_configuration, try all, in order.
* The user must specify HTTP or HTTPS in the URL.
* stboot will do string replacement on $ID and $AUTH using the values from `host_configuration.json`:
    * e.g. https://provisioning.foo.net/api/v1/?id=$ID&auth=$AUTH 
    * e.g. https://provisioning.bar.net/api/v1/$ID

These URLs are supposed to server the OS package descriptor.

For each provisioning server URL in `host_configuration.json`:
* Try downloading the OS package descriptor (json file).
* Extract the OS package URL.
* Check the filename in the OS package URL. (must be `.zip`)
    * Compare the provisioning server OS package filename with the one in the cache. Download if they don’t match.
* Try downloading the OS package

In case the provisioning server is down the operator has to choose whether to fall back on the local cache or fail. This choice results in either risking a downgrading attack or a DoS attack.

* Save the path name to the OS package which is about to be booted in `STDATA/stboot/etc/current_ospkg_pathname`
     * (all caps note in case of uncached network loaded os package)
* Cache path: `STDATA/stboot/os_pkgs/cache/`

### Local boot
* Local storage: `STDATA/stboot/os_pkgs/local/`
* Try OS packages in the order they are listed in the file
`STDATA/stboot/os_pkgs/local/boot_order`
* Save the path name to the OS package which is about to be booted in `STDATA/stboot/etc/current_ospkg_pathname`

If OS package signature verification fails, or OS package is invalid stboot will move on to the next OS package.
The operator should notice that the old OS package had been booted, and infer that the new OS package is invalid.
If OS package signature verification succeeds, OS package is valid, but running OS is inaccessible (due to failure during kexec or later), this is out of scope for stboot’s responsibility.

## Signature Verification

stboot verifies the signatures before opening an OS package.
SHA256 should be used to hash the OS package ZIP archive file. The Signature should be calculated from the resulting hash.
An OS package is signed using one or more X.509 signing certificates.
The root certificate for the signing certificates is packed into the LinuxBoot initramfs at `/etc/ospkg_signing_root.pem`. Also, the minimum number of signatures required resides in the initramfs in `etc/security_configuration.json`. Ed25519 is recommended for the root certificate as well as the signing certificates.

Two files are involved, the OS package itself and a corresponding descriptor file:
* SOMENAME.zip (package file)
* SOMENAME.json (descriptor file)

Verification process in stboot:
* Validate the document format.
* For each signature certificate tuple:
    * Validate the certificate against the root certificate.
        Only check validity bounds and if the certificate is chained to the trusted root certificate.
    * Check for duplicate X.509 certificates.
    * Verify signature.
    * Increase count of valid signatures
* Check if the number of successful signatures is enough.

# Intel® Trusted Execution Technologie (TXT) and Measured Boot

stboot is designed to opportunistically use platform security features supported by stboot, the machine it runs on, and the OS package it loads.

stboot supports the platform security features TPM 2.0, TPM 1.2, and Intel TXT. TPM 2.0 is preferred above TPM 1.2, and using Intel TXT is preferred above not using Intel TXT. stboot does not support requiring the use of a TPM or Intel TXT.

When using TPM 1.2 we use SHA-1. When using TPM 2.0 we use SHA-256. If a TPM is present stboot will measure the entire OS package ZIP file and the descriptor into the TPM before executing it. stboot will also measure the contents of https_roots.pem, ospkg_signing_root.pem, and security_configuration.json from the initramfs.

If the machine has a TPM, supports Intel TXT, and the OS package contains tboot (Intel’s TXT pre-execution environment), stboot will use Intel TXT and the TPM to measure the OS package before executing it.

If the machine has a TPM but doesn’t support Intel TXT, or if the OS package doesn’t contain tboot, stboot will use the TPM to measure the OS package before executing it.

If the machine does not have a TPM, stboot will execute the OS package without measuring it. In this case it doesn’t matter if the machine supports Intel TXT or the OS package contains tboot, as Intel TXT requires a TPM.

Note that stboot will always verify the signatures on the OS package before executing it, regardless of what platform security features are available on the machine.


# Debugging

## Console output
The output of stboot can be controlled via the LinuxBoot kernel command line. You can edit the command line in `run.config`. Beside usual kernel parameters you can pass flags to stboot via the special parameter `uroot.uinitargs`. 
* To enable debug output in stboot pass `-debug`
* To see not only the LinuxBoot kernel's but also stboot's output on all defined consoles (not on the last one defined only) pass `-klog`

Examples:

* print output to multiple consoles: `console=tty0 console=ttyS0,115200 printk.devkmsg=on uroot.uinitargs="-debug -klog"` (input is still taken from the last console defined. Furthermore, it can happen that certain messages are only displayed on the last console)

* print minimal output: `console=ttyS0,115200`

## u-root shell
By setting `ST_LINUXBOOT_VARIANT=full` in `run.config` the LinuxBoot initramfs will contain a shell and u-root's core commands (https://github.com/u-root/u-root/tree/stboot/cmds/core) in addition to stboot itself. So while stboot is running you can press `ctrl+c` to exit. You are then dropped into a shell and can inspect the system and use u-roots core commands.

## Remote Debugging Using the CPU Command
In order to do extensive remote debugging of the host, you can use u-root's cpu command. Since the stboot image running on the host has much fewer tools and services than usual Linux operating systems, the `cpu` command is a well suited option for debugging the host remotely.
It connects to the host, bringing all your local tools and environment with you.

You need to set `ST_LINUXBOOT_VARIANT=debug` in `run.config` in order to include the cpu daemon into the LinuxBoot initramfs.

The cpu command (the counterpart to the daemon) should be installed on your system as part of the toolchain. Try to run it:

``` bash
./cache/go/bin/cpu
Usage: cpu [options] host [shell command]:
  -bin string
        path of cpu binary (default "cpud")
  -bindover string
        : separated list of directories in /tmp/cpu to bind over / (default "/lib:/lib64:/lib32:/usr:/bin:/etc:/home")
  -d    enable debug prints
  -dbg9p
        show 9p io
  -hk string
        file for host key
  -init
        run as init (Debug only; normal test is if we are pid 1
  ...
```

### Usage

Before accessing the remote machine through `cpu` you first need to start the cpu daemon on the host running stboot. To do so, go to the serial console and press `ctrl+c` while stboot is running. This will give you access to the shell. Then do:

``` bash
# Start the `cpud` with all the required keys.
elvish start_cpu.elv
```

Now, on your own system run:

``` bash
cpu -key out/keys/cpu_keys/cpu_rsa <host>
```

This will connect you to the remote server and bring all your tools and environment with it. Be aware that this process might take up to a few minutes depending on the size of your environment and the power of the remote machine.

You can test it for example with your stboot MBR installation option running in qemu:
``` bash 
# run MBR bootloader installation in qemu
make run-mbr-bootloader
# interrupt stboot while booting
ctrl+c
# start the cpu daemon
./elvish start_cpu.elv
```

In the newly opened terminal run:
``` bash
cpu -key keys/cpu_keys/cpu_rsa localhost
```

# Development
This repository uses its own path (`GOPATH=cache/go`) to build the needed Go binaries by default.
To use the default system GOPATH, define `ST_DEVELOP=1` as an environment variable. It will prevent
any `git checkout` operation, which could change the HEAD of any Go repository at build-time. Furthermore, you can
define the environment variable `ST_GOPATH` to use a custom GOPATH for the installation.
