# System Transparency Tooling

This repository contains scripts, configurations files and example date to form
a build-, test- and development environment for _System Transparency_.
The source code of the various components resides in the appropriate repositories.
Detailed information about the project itself can be found at https://system-transparency.org.

Each folder contains an own README.md describing its content and the purpose of the files.

## Table of Content

| Directory                                                                                           | Description                                                    |
| --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| [`/`](#scripts)                                                                                     | entry point                                                    |
| [`configs/`](configs/#configs)                                                                      | configuration of operating systems                             |
| [`deploy/`](deploy/#deploy)                                                                         | scripts and files to build firmware binaries                   |
| [`deploy/coreboot-rom/`](deploy/coreboot-rom/#deploy-coreboot-rom)                                  | (work in progress)                                             |
| [`deploy/mixed-firmware/`](deploy/mixed-firmware/#deploy-mixed-firmware)                            | disk image solution                                            |
| [`keys/`](keys/#keys)                                                                               | example certificates and signing keys                          |
| [`operating-system/`](operating-system/#operating-system)                                           | folders including scripts ans files to build reprodu>          |
| [`operating-system/debian/`](operating-system/debian/#operating-system-debian)                      | reproducible debian buster                                     |
| [`operating-system/debian/docker/`](operating-system/debian/docker/#operating-system-debian-docker) | docker environment                                             |
| [`stboot/`](stboot/#stboot)                                                                         | scripts and files to build stboot bootloader from source       |
| [`stboot/include/`](stboot/include/#stboot-include)                                                 | fieles to be includes into the bootloader's initramfs          |
| [`stboot/data/`](stboot/data/#stboot-data)                                                          | fieles to be placed on a data partition of the host            |
| [`stconfig/`](stconfig/#stconfig)                                                                   | scripts and files to build the bootloader's configuration tool |

## Prerequisites

* Linux system (tested with Ubuntu 18.04.2 LTS (Bionic Beaver) / Kernel 4.15.0-47-generic
* Golang v 1.13 (see [install Go](https://golang.org/doc/install#install))
	* make sure to also create a workspace at `$HOME/go` (see [test Go](https://golang.org/doc/install#testing))
	* make sure `$HOME/go/bin` and `/usr/local/go/bin` or '/usr/bin/go are added to `PATH` environment variable
    * you may have to disable `GO111MODULE` via `go env -w GO111MODULE=off`
* QEMU emulator (tested with version 2.11.1)
* Server with SSH access supporting HTTPS web requests to use for your provisioning server
* Docker for building the a reproducible debian buster kernel and initramfs
* GCC 8


You then need to make GCC 8 the default.

```bash
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 --slave /usr/bin/g++ g++ /usr/bin/g++-8
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100 --slave /usr/bin/g++ g++ /usr/bin/g++-9
sudo update-alternatives --config gcc
```

Further dependency checks will be made during setup.

## Configure stboot

To control the printed output of stboot in the mixed firmware scenario see
[syslinux.cfg](deploy/mixed-firmware/#syslinux.cfg). Many other configurations
are controlles via special files like described in the DETAILS section at
[system-transparency.org](https://www.system-transparency.org/)

## Keys

This directory contains directories containing some example keys for different tasks:

- `signing_keys`: Contains the keys for signing the bootball
- `cpu_keys`: Contains the keys for using the cpu command for debugging
  - `cpu_rsa`/ `cpu_rsa.pub`: These keys are used for connecting _to_ the machine running the `cpud` server
  - `ssh_host_rsa_key`/ `ssh_host_rsa_key.pub`: These keys are used by the `cpud` server to connect _back to your_ machine.

If these directories are missing, this is because they do not exist by default
but are created, by running the `./run.sh` script which in turn runs the
`generate_keys_and_certs.sh` script.

## Deploy

The _stboot_ bootloader can be deployed to a host in different ways.
The subdirectories cover these solutions.

In general speaking _stboot_ is part of the host's firmware and comes as a
flavor of _linuxboot_, more precisely as part of the _u-root_ initramfs inside
_linuxboot_.

See also:

- https://www.linuxboot.org/
- https://github.com/u-root/u-root

## Deploy Mixed-Firmware

This deployment solution can be used if no direct control over the host
default firmware is given. Since the _stboot_ bootloader uses the
_linuxboot_ architecture it consists of a Linux kernel and an initfamfs,
which can be treated as a usual operating system. The approach of this
solution is to create an image including this kernel and initramfs.
Additionally, the image contains an active boot partition with a
separate bootloader written to it. _Syslinux_ is used here.

The image can then be written to the host's hard drive. During the boot
process of the host's default firmware the _Syslinux_ bootloader is called and
finally hands over control to the \*stboot bootloader.


## Stboot Data

Files in this folder are ment to be places in a data partition on the host
machine. This partition will be mounted by the bootloader.

## Operating-System

The operating systems to be used with _System Transparency_ need to be build
reproducible. See http://system-transparency.org for further information.

Currently the only supported system is a reproducible _Debian_ build.

## Stconfig

_Stboot_ itself is part of the _u-root_ project (https://github.com/u-root/u-root)
and is written in Go. Since _Stboot_ is still in a beta phase at the moment,
the code resides at https://github.com/u-root/u-root/tree/stboot branch.

One part of the _u-root_ project is the 'u-root' command to create an initramfs
(an archive of files) to use with Linux kernels. Another part is a collection
of bootloaders implemented in Go. _Stboot_ is one of these bootloaders.

The _u-root_ project also includes some tools related to its various commands.
_Stconfig_ is a tool for the host's operator to prepare a bootball file ('stboot.ball')
for the provisioning server. This file is downloaded to the host during the
_Stboot's_ bootprocess. _Stboot_ is heavily dependent on that bootball being
prepared by this tool.
Usually the generated bootball should work for all hosts.
But if there is the need for a host specific bootball, you can create a unique bootball
identified by the MAC address of the appropriate server.
The host will look for a specific boot ball on the provisioning server first.
If none is present, the host will download the general one.

See `stconfig --help-long` for inforamtion on how to parse the MAC address.

See https://system-transparency.org for further information about 'stconfig.json' and 'stboot.ball'.

This directory mainly provides utilities for the ongoing development.

#### `run.sh`

This script is the global entry point to build up or update the environment.
It runs a dependency check and prompts you to execute all other necessary
scripts and thereby leads through the whole setup process. Each step can be run,
run with special options where applicable or skipped.
In this way you can also only renew certain parts of the environment.
Run each step when executing for the first time.

Some scripts need root privileges.

The file `run.config` contains configuration variables and should be edited
prior to the running of `run.sh`.

