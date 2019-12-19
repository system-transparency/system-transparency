# System Transparency Tooling
This repository contains scripts, configurations files and example date to form a build-, test- and development environment for *System Transparency*.
The source code of the various components resides in the appropriate repositories. Detailed information about the project itself can be found at https://docs.system-transparency.org.

Each folder contains an own README.md describing its content and the purpose of the files.

## Table of Content
Directory | Description
------------ | -------------
[`/`](##/joj) | entry point
[`configs/`](configs/README.md) | configuration of operating systems
[`deploy/`](deploy/README.md) | scripts and files to build firmware binaries
[`deploy/coreboot-rom`](deploy/coreboot-rom/README.md) | (work in progress)
[`deploy/mixed-firmware`](deploy/mixed-firmware/README.md) | disk image solution
[`keys/`](keys/README.md) | example certificates and signing keys
[`operating-system/`](operating-system/README.md) | folders including scripts ans files to build reproducible operating systems
[`operating-system/debian`](operating-system/debian/README.md) | reproducible debian buster
[`operating-system/debian/docker`](operating-system/debian/docker/README.md) | docker environment
[`stboot/`](stboot/README.md) | scripts and files to build stboot bootloader from source 
[`stboot/include`](stboot/include/README.md) | fieles to be includes into the bootloader's initramfs
[`stconfig/`](stconfig/README.md) | scripts and files to build the bootloader's configuration tool from source

## /joj
### Scripts
#### `run.sh`
This script is the global entry point to build up or update the environment.
It runs a dependency check and prompts you to execute all other necessary scripts and thereby leads through the whole setup process. Each step can be run, run with special options where applicable or skipped. In this way you can also only renew certain parts of the environment.
Run each step when executing for the first time. Some scripts need root privileges.

#### `start_qemu_mixed-firmware.sh`
This script is invoked by `run.sh`. It will boot up *qemu* to test the system. All output is printed to the console.
Use `ctrl+a` , `x` to terminate.

