# System Transparency Tooling

This repository contains scripts, configurations files and example data to form
a build-, test- and development environment for _System Transparency_.
The source code of the various components resides in the appropriate repositories.
Detailed information about the project itself can be found at https://system-transparency.org.

## Prerequisites

Regarding the system components refer to https://www.system-transparency.org/operator-guide/get-system-transparency-up-and-running
* The operator machine should run a Linux system (tested with Ubuntu 18.04.2 LTS (Bionic Beaver) / Kernel 4.15.0-47-generic
* Further software prerequisites will be checked during setup. For details take a look at `./scripts/checks.sh`. 

Regarding Golang:
* make sure to also create a workspace at `$HOME/go` (see [test Go](https://golang.org/doc/install#testing))
* make sure `$HOME/go/bin` and `/usr/local/go/bin` or '/usr/bin/go are added to `PATH` environment variable
  * you may have to disable `GO111MODULE` via `go env -w GO111MODULE=off`

If the dependency checks complains about your GCC, You need to make GCC 8 the default:

```bash
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 --slave /usr/bin/g++ g++ /usr/bin/g++-8
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100 --slave /usr/bin/g++ g++ /usr/bin/g++-9
sudo update-alternatives --config gcc
```

## Quick Start

```bash
./run.sh
```
This will lead you through the process described in [Build Process in Detail].

## Features

* Configuration data
    * Hostvars
    * Data partition
* Time validation
* TXT self test
* multiple boot modes for loading System Transparency _Bootballs_ 
    * Network DHCP
    * Nework static IP
    * Local storage
* Signature verification
    * Root certificate validation
    * Multiple signature verification of _Bootballs_
* Measured boot
    * Extend PCRs with measurement of operation system
* Reboot on error
* Configurable Debug output
* Optional remote debugging capabilities

## Build Process in Detail
There are two main parts to build. You need an operating system which is reproducible and completely self-contained in a Linux kernel + initramfs. Then you need to build the _stboot_ bootloader depending on your deploymet scenario. Further you need some additional things likes keys to be set up and at the right place. To be able to build these components you need to build a tool chain once.

### Tool Chain

```bash
./scripts/make_toolchain.sh
```

### Keys
The blob containing the operating system, called _bootball_ needs to be signed. You can use your own keys or create new ones with:

```bash
./scripts/make_keys_and_certs.sh
```

The created directory `./keys/` contains:
- `signing_keys/`: Contains the keys for signing the bootball
- `cpu_keys/`: Contains the keys for using the cpu command for debugging

### Configuration Files
The components, especially the bootloader require certain configuration files to work. These files can be generated with the information inside the global configuration `run.config` by calling:

```bash
./scripts/make_example_data.sh
```

### Operating System and Bootball
The operating systems to be used with _System Transparency_ need to be build reproducible. Currently, the only supported OS by this tooling is Debian Buster.

```bash
./operating-system/debian/make_debian.sh
```

After the kernel and initramfs being created use the _stmanager_ utility to create a sign a bootball from it.
See `stmanager --help-long` or to make use of the generated keys form `./scripts/make_keys_and_certs.sh` call:

```bash
./scripts/create_and_sign_bootball.sh
```

If you want to go with the netboot feature of _stboot_ have set the corresponding parameters in `run.config` you can upload the bootball to your provisioning server with:

```bash
./scripts/upload_bootball.sh
```

### Bootloader (stboot)
System Transparency Boot (stboot) is [LinuxBoot](https://www.linuxboot.org/) distribution. The initial RAM filesystem (initramfs) is created by the [u-root](https://github.com/u-root/u-root) ramfs builder. Since u-root beside being a ramfs builder is also a collection of different bootloader implementations, the codebase of _stboot_ is part of u-root, too.

Regarding deployment, we defined three real world scenarios which should at least support a high chance that we have covered a lot of hardware systems. We categorized the scenarios based on the firmware with levels. With the lowest firmware level it is possible to make the whole system stack transparent.

#### Leased server with mixed-firmware scenario (FL3)
Bringing system transparency to already existing hardware which can’t be transformed to open source firmware machines is troublesome. Therefore, we need to propose a solution which even works on those limited systems. We will use a standard Ubuntu 18.04 server edition and standard bootloader to load _stboot_. This scenario is especially helpful for a server landscape with mixed firmware like BIOS and UEFI.

```bash
./stboot/mixed-firmware/make_image.sh
```

You need to deploy the created`./stboot/mixed-firmware/stboot_mixed_firmware_bootlayout.img` to the hard drive of your host. It contains a _STBOOT_ partition containing the bootloader and a _STDATA_ partition containing configuration data for both bootloader and operating system. The MBR is written accordingly.

#### Leased server with UEFI-firmware scenario (FL2)
In this scenario we have a closed source UEFI firmware which cannot easily be modified. In order to deploy _stboot_ underneath, we will use the Linux EFI stub kernel feature and compile the kernel as EFI application.

```bash
./stboot/uefi-firmware/make_image.sh
```

You need to deploy the created`./stboot/mixed-firmware/stboot_uefi_firmware_bootlayout.img` to the hard drive of your host. It contains a _STBOOT_ partition containing the bootloader and a _STDATA_ partition containing configuration data for both bootloader and operating system. _STBOOT_ in this case is an EFI special partition containing the bootloader as an efistub.

#### Colocated server with Open Source firmware scenario (FL1)
In this scenario we are able to place our own server in the data center. This server already contains Open Source firmware and is able to boot a Linux kernel payload after hardware initialization.

This process is not automated yet. Only the _STDATA_ partition can be generated using:

```
./stboot/coreboot-firware/make_image.sh
```

To build and flash the coreboot-rom including _stboot_ as a payload, please refer to [this instructions](stboot/coreboot-firmware/#deploy-coreboot-rom). 
You need to deploy the created`./stboot/coreboot-firmware/stdata.img` to the hard drive of your host. It contains a _STDATA_ partition only.

## Debugging
The output of stboot can be controlled via the LinuxBoot kernel command line. You can edit the command line in the section of respective firmware scenario. Beside usual kernel parameters you can pass flags to _stboot_ via the special parameter `uroot.uinitargs`. 
* To enable debug output in _stboot_ pass `-debug`
* To see not only the LinuxBoot kernel's but also stboot's output on all defined consoles (not on the last one defined only) pass `-klog`

Examples:

* print output to multiple consoles: `console=tty0 console=ttyS0,115200 printk.devkmsg=on uroot.uinitargs="-debug -klog"` (input is still taken from the last console defined. Furthermore, it can happen that certain messages are only displayed on the last console)

* print minimal output: `console=ttyS0,115200`

In order to do extensive remote debugging of the host, you can use [u-root's cpu command](DEBUGGING.md).
