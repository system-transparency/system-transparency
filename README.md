# System Transparency Tooling

This repository contains tooling, configuration files and, demos to form a build-, test- and development environment for _System Transparency_.

_stboot_ is System Transparency Project’s official bootloader. It is a [LinuxBoot](https://www.linuxboot.org/) distribution based on [u-root](https://github.com/u-root/u-root). The source code of stboot can be found at https://github.com/system-transparency/stboot.

With System Transparency, all OS-related artifacts including the userland are bundled together in a signed [OS Package](#OS-Package). The core idea is that stboot verifies this OS package before booting. For more details on signature verification, further security mechanisms and features of stboot see [Features](#Features)

* [Prerequisites](#Prerequisites)
    * [Task - our build tool](#About-task)
    * [Environment](#Environment)
    * [Build Dependencies](#Build-Dependencies)
    * [Demo Files](#Demo-Files)
* [Installation](#Installation)
    * [Configure](#Configure)
    * [Build](#Build)
    * [Test](#Test)
* [OS Package](#OS-Package)
* [Deployment](#Deployment)
    * [MBR Bootloader Installation](#Leased-server-with-MBR-bootloader-installation)
    * [EFI Application Installation](#Leased-server-with-EFI-application-installation)
    * [coreboot Payload Installation](#Colocated-server-with-coreboot-payload-installation)
* [System Configuration](#System-Configuration)
    * [Configuration of stboot](#Configuration-of-stboot)
        * [host_configuration.json](#host_configuration.json)
        * [security_configuration.json](#security_configuration.json)
    * [Modify LinuxBoot kernel config](#Modify-LinuxBoot-kernel-config)
* [Features](#Features)
    * [System Time Validation](#System-Time-Validation)
    * [Boot Modes](#Boot-Modes)
        * [Network Boot](#Network-Boot)
        * [Local Boot](#Local-Boot)
    * [Signature Verification](#Signature-Verification)
    * [Intel® Trusted Execution Technologie (TXT) and Measured Boot](#Intel®-Trusted-Execution-Technologie-(TXT)-and-Measured-Boot)
* [Debugging](#Debugging)
    * [Console Output](#Console-Output)
    * [u-root Shell](#u-root-Shell)
    * [Remote Debugging Using the CPU Command](#Remote-Debugging-Using-the-CPU-Command)
        * [Preparation](#Preparation)
        * [Usage](#Usage)
* [Development](#Development)

# Prerequisites
Your machine should run a Linux system (tested with Ubuntu 18.04.2 LTS and 20.04.2 LTS).

## About task

[Task](https://taskfile.dev) is a task runner/build tool that aims to be simpler and easier to use than, for example, [GNU Make](https://www.gnu.org/software/make/). It provides remarkable documentation and uses a simple YAML schema to define tasks. For more information, go to https://taskfile.dev or run `task --help`.

To see all available tasks:

```bash
task -l
```
### Migration to Task

In previous versions, System Transparency used GNU make to build the target installation. If your repository still has build artifacts from make, it is recommended to clean the complete repository before using it with task:

```bash
task clean-all
```

## Environment

The System Transparency Repository provides a `.envrc` file to load the build environment. It installs the latest version of [Task](https://taskfile.dev) and configures a separate Go environment to prevent any conflicts. To load and unload the environment depending on the current directory, it is recommended to use [direnv](https://direnv.net/). Go to [Basic Installation](https://direnv.net/#basic-installation) to see how to properly setup direnv your shell.
After restarting your shell, you can enable direnv for the repository:

```bash
cd system-transparency
direnv allow
```

As an alternative, you can load the environment directly without direnv:

```bash
source .envrc
```

However, this is only recommended on CI workflows since it makes the environment changes persistent in your current shell session.

## Build Dependencies
This is work in progress.

System Transparency requires some dependencies to build the complete installation image. You can check for missing dependencies:

```bash
task deps:check
```

In addition, it is possible to install all dependencies on Debian based environments (tested with Ubuntu 18.04.2 LTS and 20.04.2 LTS):

```bash
task deps:install
```
`Note: user requires privileges via sudo`


## Demo Files

To see System Transparency in action you need a signed OS package to be loaded by stboot, it is possible to create an Image for demo purposes.

First, generate all required keys and certificates for the signature verification:

```bash
task demo:keygen
```

Afterward, an example OS package can be built with:

```bash
task demo:ospkg
```

It builds an example Debian OS image with [debos](https://github.com/go-debos/debos) and uses stmanager to convert it to an OS package.


# Installation
To bring System Transparency to your systems, you need to deploy an installation image. Run the following to create an image.
See [Deployment](#Deployment) for the supported scenarios.

## Configure

To generate a default configuration:

```bash
task config
```

The config file `st.config` contains all available configuration variables. Take a look at the descriptions provided in this file for details.

## Build 
```bash
task image
```

## Test
``` bash 

# run target installation
task run
```

# OS-Package
An OS package consists of an archive file (ZIP) and descriptor file (JSON). The archive contains the boot files (kernel, initramfs, etc.) and the descriptor file contains the signatures and other metadata.

OS packages can be created and managed with the _stmanager_ tool. Source code of stmanager: https://github.com/system-transparency/stboot/tree/main/tools/stmanager

Once you have an OS kernel & initramfs containing the userspace and optionally a tboot kernel and appropriate ACM for TXT create an OS package out of it:
``` bash
# Create a new OS package
stmanager create --kernel=<your_OS_kernel> --initramfs=<your_OS_initramfs>
# Sign the OS package (multiple times)
stmanager sign --key=<your.key> --cert=<your.cert> <OS package>

# See help for all options
stmanager --help-long

```
According to the configured boot mode, place the OS package(s) at the STDATA partition of the stboot image or upload it to a provisioning server. See [Boot Modes](#Boot-Modes)

# Deployment
Regarding deployment, we defined three real-world scenarios which should at least support a high chance that we have covered a lot of hardware systems. The installation option can be set via `ST_INSTALLATION_OPTION` in `.config`.

## Leased server with MBR bootloader installation
Bringing system transparency to already existing hardware that can’t be transformed to open source firmware machines is troublesome. Therefore, we need to propose a solution which even works on those limited systems. This scenario is especially helpful for a server landscape with mixed firmware like BIOS and UEFI. Syslinux is used as an intermediate bootloader. There is both, valid boot code in the MBR (for legacy systems) and a .efi file on the first partition (for EFI systems) to load stboot. The disadvantage is that there is no guaranteed TPM measurement of the stboot code in the installation option.

When built as an MBR bootloader there is one artifact `out/stboot-installation/mbr-bootloader/stboot_mbr_installation.img`containing:
* SYSLINUX (for the Master Boot Record)
* A VFAT/FAT32 partition named STBOOT containing:
    * Syslinux configuration
    * Syslinux boot files
    * LinuxBoot files
    * Host configuration for stboot
* An Ext4 partition named STDATA containing
    * An OS package if the boot method is set to _local_.
    * An empty directory for use as a cache if the boot method is set to _network_.

You need to write this image to the hard drive of the host.

## Leased server with EFI application installation
In this scenario, we have a closed source UEFI firmware that cannot easily be modified. To deploy _stboot_ underneath, we will use the Linux EFI stub kernel feature and compile the kernel as an EFI application. The idea is to take advantage of the TPM measurements done by the efi firmware. stboot (kernel + initramfs compiled into this kernel) is built as an EFI executable / efi application in this installation option. This artifact resides at a partition marked as ESP (EFI special partition). The efi firmware measures this file before execution (even with secure boot disabled in our tests). 

When built as an EFI application there is one artifact `out/stboot-installation/efi-application/stboot_efi_installation.img` containing:
* A VFAT/FAT32 partition named STBOOT marked as an EFI system partition containing:
    * LinuxBoot files compiled as an EFI stub
    * Host configuration for stboot
*An Ext4 partition named STDATA containing:
    * An OS package if the boot method is set to _local_.
    * An empty directory for use as a cache if the boot method is set to _network_.

You need to write this image to the hard drive of the host.

## Colocated server with coreboot payload installation
In this scenario, we can place our own server in the data center. This server already contains Open Source firmware and can boot a Linux kernel payload after hardware initialization.

_WORK IN PROGRESS_

When built as a coreboot payload there will be two artifacts:
* A file named coreboot.rom containing an SPI flash image.
* A file named stboot_coreboot_installation.img containing:
    * A VFAT/FAT32 partition named STBOOT containing:
        * Host configuration for stboot
    * An Ext4 partition named STDATA containing:
        * An OS package if the boot method is set to _local_.
        * An empty directory for use as a cache if the boot method is set to _network_.

You need to write the coreboot.rom to the SPI Flash of the host and write the image to the hard drive of the host.
To build and flash the coreboot-rom including _stboot_ as a payload, please refer to [these instructions](stboot-installation/coreboot-payload/#deploy-coreboot-rom). 

# System Configuration

## Configuration of stboot
Most options can be set in `run.config`. See the descriptions there for details.

A subset of the configuration options in `.config` end up in two JSON files which stboot reads in during the boot process:

### host_configuration.json
This file is written to the root directory of the STBOOT partition. It contains host-specific data and resides on the STBOOT partition, so it can easily be modified during an orchestration process. It contains a single JSON object that stboot parses. The JSON object has the following fields:

#### `version ` - JSON number
The version number of the host configuration.

#### `network_mode` - JSON string
Valid values are `"static"` or `"dhcp"`. In network boot mode it determines the setup of the network interface. Either the DHCP protocol is used or a static IP setup using the values of the fields `host_ip` and `gateway`.

#### `host_ip` - JSON string
Only relevant in network boot mode and when `network_mode` is set to `"static"`. The machine's network IP address is supposed to be passed in CIDR notation like "192.0.2.0/24" or "2001:db8::/32".

#### `gateway` - JSON string
Only relevant in network boot mode and when `network_mode` is set to `"static"`. The machine's network default gateway is supposed to be passed in CIDR notation like "192.0.2.0/24" or "2001:db8::/32".

#### `dns` - JSON string
Optional setting to pass a custom DNS server when using network boot mode. The value will be prefixed with `nameserver` and then written to `/etc/resolv.conf` inside the LinuxBoot initramfs. If no own setting is provided, `8.8.8.8` is used.

#### `network_interface` - JSON string
Optional setting to choose a specific network interface via its MAC address when using network boot mode. The MAC is supposed to be passed in IEEE 802 MAC-48, EUI-48, or EUI-64 format, e.g `00:00:5e:00:53:01`.  If empty or if the desired network interface cannot be found, the first existing and successfully setup one will be used.

#### `provisioning_urls` - JSON array of strings
A list of provisioning server URLs. See also [Network Boot](#Network-Boot). The URLs must include the scheme (`http://` or `https://`).

#### `identity` - JSON string
This string representation of random hex-encoded 256 bits is used for string replacement in the provisioning URLs. See [Network Boot](#Network-Boot).

#### `authentication` - JSON string
This string representation of random hex-encoded 256 bits is used for string replacement in the provisioning URLs. See [Network Boot](#Network-Boot).

An example host_configuration.json file could look like this:
``` json
{
    "version":1,
    "network_mode":"static",
    "host_ip":"10.0.2.15/24",
    "gateway":"10.0.2.2/24",
    "dns":"8.8.8.8",
    "provisioning_urls": ["http://a.server.com","https://b.server.com"],
    "identity":"8D4EA31D49AF0EB93FAB198D3FD874B0A2C7C4C4351F28A7967C8D674FE508DC",
    "authentication":"C2F3F516A79F756E7D3128B77077B4A8AEF61E888499FD99AE92E6D4F2E7653C"
}
```
All values can be managed via `.config` so although you can easily modify this file on the image. Generally, it is recommended not to edit this file manually but control the values via the general configuration.

### security_configuration.json
This file is compiled into the LinuxBoot initramfs at `/etc/security_configuration.json`. It contains the following security-critical fields it is not recommended to edit this file manually. It contains a single JSON object that stboot parses. The JSON object has the following fields:

#### `version ` - JSON number
The version number of the security configuration.

#### `min_valid_sigs_required ` - JSON number
This value determines the minimum number of signatures that must be valid during the validation of an OS package. See [Signature Verification](#Signature-Verification)

#### `boot_mode ` - JSON string
Valid values are `"local"` or `"network"`. See [Boot Modes](#Boot-Modes).

#### `use_ospkg_cache ` - JSON boolean
Only relevant when using network boot mode. In case the provisioning server is down this setting controls whether to fall back on the local cache or fail. This choice results in either risking a downgrading attack or a DoS attack.

An example security_configuration.json file could look like this:
``` json
{
  "version": 1,
  "minimal_signatures_match": 2,
  "boot_mode": "local",
  "use_ospkg_cache": false
}

# Features

stboot extensively validates the state of the system and all data it will use in its control flow. In case of any error, it will reboot the system. At the end of the control flow, stboot will use kexec to hand over the control to the kernel provided in the OS package. From that point on stboot has no longer control over the system.

## System Time Validation
A proper system time is important for validating certificates. It is the responsibility of the operator to set the system time correctly. However, stboot performs the following check:

* Look at the system time, look at the timestamp on `STDATA/stboot/etc/system_time_fix`
* Set system time to the latest.

The OS is allowed to update this file. Especially if it’s an embedded system without an RTC.

## Boot Modes
stboot supports two boot methods - Network and Local. In _Network_ mode stboot loads an OS package from a provisioning server. In _Local_ mode stboot loads an OS package from the STDATA partition on a local disk. Only one boot method at a time may be configured.

### Network Boot
Network boot can be configured using either DHCP or a static network configuration. In the case of a static network, stboot uses IP address, netmask, default gateway, and DNS server from `host_configuration.json`. The latest downloaded and verified OS package can be cached depending on settings in `security_configuration.json`. Older ones are removed. The cache directory is separate from the directory used by the Local boot method.

Provisioning Server Communication:
* The HTTPS root certificates are stored in the LinuxBoot initramfs
    * File name: `/etc/https_roots.pem`
    * Use https://letsencrypt.org/certificates/ roots as default.

Provisioning URLs:
* If multiple provisioning URLs are present in host_configuration, try all, in order.
* The user must specify HTTP or HTTPS in the URL.
* stboot will do string replacement on $ID and $AUTH using the values from `host_configuration.json`:
    * e.g. https://provisioning.foo.net/api/v1/?id=$ID&auth=$AUTH 
    * e.g. https://provisioning.bar.net/api/v1/$ID

These URLs are supposed to serve the OS package descriptor.

For each provisioning server URL in `host_configuration.json`:
* Try downloading the OS package descriptor (JSON file).
* Extract the OS package URL.
* Check the filename in the OS package URL. (must be `.zip`)
    * Compare the provisioning server OS package filename with the one in the cache. Download if they don’t match.
* Try downloading the OS package

In case the provisioning server is down the operator has to choose whether to fall back on the local cache or fail. This choice results in either risking a downgrading attack or a DoS attack.

* Save the pathname to the OS package which is about to be booted in `STDATA/stboot/etc/current_ospkg_pathname`
     * (all caps note in case of uncached network loaded OS package)
* Cache path: `STDATA/stboot/os_pkgs/cache/`

### Local Boot
* Local storage: `STDATA/stboot/os_pkgs/local/`
* Try OS packages in the order they are listed in the file
`STDATA/stboot/os_pkgs/local/boot_order`
* Save the pathname to the OS package which is about to be booted in `STDATA/stboot/etc/current_ospkg_pathname`

If OS package signature verification fails, or the OS package is invalid, stboot will move on to the next OS package.
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

The verification process in stboot:
* Validate the document format.
* For each signature certificate tuple:
    * Validate the certificate against the root certificate.
        Only check validity bounds and if the certificate is chained to the trusted root certificate.
    * Check for duplicate X.509 certificates.
    * Verify signature.
    * Increase count of valid signatures
* Check if the number of successful signatures is enough.

## Intel® Trusted Execution Technology (TXT) and Measured Boot

stboot is designed to opportunistically use platform security features supported by stboot, the machine it runs on, and the OS package it loads.

stboot supports the platform security features TPM 2.0, TPM 1.2, and Intel TXT. TPM 2.0 is preferred above TPM 1.2, and using Intel TXT is preferred above not using Intel TXT. stboot does not support requiring the use of a TPM or Intel TXT.

When using TPM 1.2 we use SHA-1. When using TPM 2.0 we use SHA-256. If a TPM is present stboot will measure the entire OS package ZIP file and the descriptor into the TPM before executing it. stboot will also measure the contents of https_roots.pem, ospkg_signing_root.pem, and security_configuration.json from the initramfs.

If the machine has a TPM, supports Intel TXT, and the OS package contains tboot (Intel’s TXT pre-execution environment), stboot will use Intel TXT and the TPM to measure the OS package before executing it.

If the machine has a TPM but doesn’t support Intel TXT, or if the OS package doesn’t contain tboot, stboot will use the TPM to measure the OS package before executing it.

If the machine does not have a TPM, stboot will execute the OS package without measuring it. In this case, it doesn’t matter if the machine supports Intel TXT or the OS package contains tboot, as Intel TXT requires a TPM.

Note that stboot will always verify the signatures on the OS package before executing it, regardless of what platform security features are available on the machine.


# Debugging

## Console Output
The output of stboot can be controlled via the LinuxBoot kernel command line. You can edit the command line in `.config`. Besides the usual kernel parameters, you can pass flags to stboot via the special parameter `uroot.uinitargs`.
* To enable debug output in stboot pass `-debug`
* To see not only the LinuxBoot kernel's but also stboot's output on all defined consoles (not on the last one defined only) pass `-klog`

Examples:

* Print output to multiple consoles: `console=tty0 console=ttyS0,115200 printk.devkmsg=on uroot.uinitargs="-debug -klog"` (input is still taken from the last console defined. Furthermore, it can happen that certain messages are only displayed on the last console)

* Print minimal output: `console=ttyS0,115200`

## u-root Shell
By setting `ST_LINUXBOOT_VARIANT=full` in `.config` the LinuxBoot initramfs will contain a shell and u-root's core commands (https://github.com/u-root/u-root/tree/stboot/cmds/core) in addition to stboot itself. So while stboot is running you can press `ctrl+c` to exit. You are then dropped into a shell and can inspect the system and use u-roots core commands.

## Remote Debugging Using the CPU Command
To do extensive remote debugging of the host, you can use u-root's cpu command. Since the stboot image running on the host has much fewer tools and services than usual Linux operating systems, the `cpu` command is a well-suited option for debugging the host remotely.
It connects to the host, bringing all your local tools and environment with you.

### Preparation
You need to set `ST_LINUXBOOT_VARIANT=debug` in `.config` to include the cpu daemon into the LinuxBoot initramfs.

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

You can test it by running in qemu:
``` bash 
# run installation in qemu
task run
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
