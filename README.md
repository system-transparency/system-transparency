# System Transparency Tooling

This repository contains scripts, configurations files and example date to form a build-, test- and development environment for _System Transparency_.
The source code of the various components resides in the appropriate repositories. Detailed information about the project itself can be found at https://system-transparency.org.

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

## /

### Scripts

#### `run.sh`

This script is the global entry point to build up or update the environment.
It runs a dependency check and prompts you to execute all other necessary scripts and thereby leads through the whole setup process. Each step can be run, run with special options where applicable or skipped. In this way you can also only renew certain parts of the environment.
Run each step when executing for the first time. Some scripts need root privileges.

On Debian-based systems you'll need the following packages:

```bash
apt install golang docker.io openssl git qemu-system-x86 wget sudo bison flex pkg-config libelf-dev libssl-dev bc libc6-i386 gcc-8 g++-8 libncurses-dev
```

You then need to make GCC 8 the default.

```bash
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 100 --slave /usr/bin/g++ g++ /usr/bin/g++-8
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100 --slave /usr/bin/g++ g++ /usr/bin/g++-9
sudo update-alternatives --config gcc
```

#### `start_qemu_mixed-firmware.sh`

This script is invoked by `run.sh`. It will boot up _qemu_ to test the system. All output is printed to the console.
Use `ctrl+a` , `x` to terminate.
