# System Transparency Tooling

This repository contains scripts, configurations files and example data to form
a build-, test- and development environment for _System Transparency_.
The source code of the various components resides in the appropriate repositories.
Detailed information about the project itself can be found at https://system-transparency.org.

## Prerequisites

* The operator machine should run a Linux system (tested with Ubuntu 18.04.2 LTS (Bionic Beaver) / Kernel 4.15.0-47-generic
* Further software prerequisites will be checked during setup. For details take a look at `./scripts/checks.sh`. 

## Quick Start

### build dependency check

```bash
# Check for missing dependencies
make check
```

### Configure stboot target installation

```bash
# make default configuration
make config
# modify configuration
${EDITOR} .config
```

### Build stboot installations

```bash
# Build MBR bootloader installation
make mbr-bootloader-installation
# Build EFI application installation
make efi-application-installation
```

### Test installation in QEMU

```bash
# run MBR bootloader installation
make run-mbr-bootloader
# run EFI application installation
make run-efi-application
```


### Modify LinuxBoot kernel config

```bash
# Run MBR bootloader kernel menuconfig
make mbr-kernel-menuconfig
# Update MBR bootloader kernel defconfig
make mbr-kernel-updatedefconfig
```

## Features

### Configuration data
security_configuration.json: Critical data included into the initramfs
* Integer controlling the minimum number of signatures that must pass verification
* String array of allowed fingerprints of root certificates for signature verification
* Build timestamp
* Custom type indicating the [boot mode](#Multiple-boot-modes-for-loading-System-Transparency-OS-packages)

Data partition: Further data supposed to be on disk
* HTTPS root certificate
* Network settings
    * IP address
    * Gateway
    * DNS Server
* NTP Server URL list
* Provisioning Server URL list

### Time validation
Proper system time is important for certificate validation. Therefore the system time is validated using NTP Servers. If no NTP Server is available the timestamp in security_configuration.json is used for the validation of the system time.

### TXT self test
Stboot uses https://github.com/9elements/converged-security-suite to run a self test on TXT compatibility.

### Multiple boot modes for loading System Transparency OS packages
Network DHCP:
* Configure network dynamically via DHCP
* Download OS package from a provisioning server
    * Request the file from the provisioning servers in the order of the URL list in security_configuration.json
    * Take the first match
    
Network static IP:
* Configure network dynamically via DHCP
* Download OS package from a provisioning server
    * Request the file from the provisioning servers in the order of the URL list in security_configuration.json
    * Take the first match
    
Local storage: 
Requires operator to place new OS packages in `DATA-PARTITION/stboot/os-pkgs/new/` and move successfully boot ones to `DATA-PARTITION/stboot/os-pkgs/known_good/`.
* Try verifying and then booting these files first, in reverse alphabetical order: `DATA-PARTITION/stboot/os-pkgs/new/*.zip
` (close to "standard ls").
* If signature verification fails on a file, move the file here: `DATA-PARTITION/stboot/os-pkgs/invalid/`.
* If no files in `DATA-PARTITION/new/` can be verified, try these files, in reverse alphabetical order: `DATA-PARTITION/stboot/os-pkgs/known_good/*.zip`.
* If one of these fail, move it into `/invalid` ,too.
 (close to "standard ls")
* Save the path to the OS package which will be booted into `DATA-PARTITION/stboot/os-pkgs/current-ospkg.zip` file


### Signature verification
A OS package includes one or more Signatures of the included boot files (kernel, initramfs, et al.) together with the corresponding certificates.
The root certificate is also included. The signature verification after downloading the OS package then works as follows:
* Validate the root certificate with the fingerprints in security_configuration.json
* Check that the certificates are signed by the root certificate
* Verify the signature of the boot files
   * Make sure there is no double signature
* The OS package will be used if minimum the number of signatures indicated in hosvars passed the verification

### Measured boot
* Extend PCRs with measurement of operation system

### Reboot on error
* Whenever an error occures during bootup, the system will reboot.

### Debugging
See [debugging section](#Debugging)


## Go toolchain Development
This repository uses its own path (`GOPATH=cache/go`) to build the needed Go binaries by default.
To use the default system GOPATH, define `ST_DEVELOP=1` as environment variable. It will prevent
any `git checkout` operation, which could change the HEAD of any Go repository at build-time. Furthermore, you can
define the environment variable `ST_GOPATH` to use a custom GOPATH for the installation.

## Build Process in Detail
There are two main parts to build. You need an operating system which is reproducible and completely self-contained in a Linux kernel + initramfs. Then you need to build the _stboot_ bootloader depending on your deployment scenario. Further you need some additional things likes keys to be set up and at the right place. To be able to build these components you need to build a tool chain once.

### Tool Chain

```bash
make toolchain
```

### Keys
The blob containing the operating system, called _OS package_ needs to be signed. You can use your own keys or create new ones with:

```bash
make keygen-sign
```

Created directories:
- `out/keys/signing_keys/`: Contains the keys for signing the OS package
- `out/keys/cpu_keys/`: Contains the keys for using the cpu command for debugging

### Operating System and OS package
The operating systems to be used with _System Transparency_ need to be build reproducible. Currently, the only supported OS by this tooling is Debian Buster.

```bash
make debian
```

After the kernel and initramfs being created use the _stmanager_ utility to create a sign a OS package from it.
See `stmanager --help-long` or to make use of the generated keys form `./scripts/make_keys_and_certs.sh` call:

```bash
make sign
```

If you want to go with the netboot feature of _stboot_ have set the corresponding parameters in `.config` you can upload the OS package to your provisioning server with:

```bash
make upload
```

### Bootloader (stboot)
System Transparency Boot (stboot) is [LinuxBoot](https://www.linuxboot.org/) distribution. The initial RAM filesystem (initramfs) is created by the [u-root](https://github.com/u-root/u-root) ramfs builder. Since u-root beside being a ramfs builder is also a collection of different bootloader implementations, the codebase of _stboot_ is part of u-root, too.

Regarding deployment, we defined three real world scenarios which should at least support a high chance that we have covered a lot of hardware systems. We categorized the scenarios based on the firmware with levels. With the lowest firmware level it is possible to make the whole system stack transparent.

#### Leased server with MBR bootloader installation
Bringing system transparency to already existing hardware which can’t be transformed to open source firmware machines is troublesome. Therefore, we need to propose a solution which even works on those limited systems. We will use a standard Ubuntu 18.04 server edition and standard bootloader to load _stboot_. This scenario is especially helpful for a server landscape with mixed firmware like BIOS and UEFI.

```bash
make mbr-bootloader-installation
```

You need to deploy the created`./stboot-installation/mbr-bootloader/stboot_mbr_installation.img` to the hard drive of your host. It contains a _STBOOT_ partition containing the bootloader and a _STDATA_ partition containing configuration data for both bootloader and operating system. The MBR is written accordingly.

#### Leased server with EFI application installation
In this scenario we have a closed source UEFI firmware which cannot easily be modified. In order to deploy _stboot_ underneath, we will use the Linux EFI stub kernel feature and compile the kernel as EFI application.

```bash
make efi-application-installation
```

You need to deploy the created`./stboot-installation/efi-application/stboot_efi_installation.img` to the hard drive of your host. It contains a _STBOOT_ partition containing the bootloader and a _STDATA_ partition containing configuration data for both bootloader and operating system. _STBOOT_ in this case is an EFI special partition containing the bootloader as an efistub.

#### Colocated server with coreboot payload installation
In this scenario we are able to place our own server in the data center. This server already contains Open Source firmware and is able to boot a Linux kernel payload after hardware initialization.

```
# Work in Progress: Not yet implemented!
#make coreboot-payload-installation
```

To build and flash the coreboot-rom including _stboot_ as a payload, please refer to [this instructions](stboot-installation/coreboot-payload/#deploy-coreboot-rom). 
You need to deploy the created`./stboot-installation/coreboot-payload/*.img` to the hard drive of your host. It contains a _STDATA_ partition only.

## Debugging
The output of stboot can be controlled via the LinuxBoot kernel command line. You can edit the command line in the section of respective firmware scenario. Beside usual kernel parameters you can pass flags to _stboot_ via the special parameter `uroot.uinitargs`. 
* To enable debug output in _stboot_ pass `-debug`
* To see not only the LinuxBoot kernel's but also stboot's output on all defined consoles (not on the last one defined only) pass `-klog`

Examples:

* print output to multiple consoles: `console=tty0 console=ttyS0,115200 printk.devkmsg=on uroot.uinitargs="-debug -klog"` (input is still taken from the last console defined. Furthermore, it can happen that certain messages are only displayed on the last console)

* print minimal output: `console=ttyS0,115200`

In order to do extensive remote debugging of the host, you can use [u-root's cpu command](DEBUGGING.md).
