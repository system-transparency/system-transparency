# System Transparency Tooling
This repository contains scripts, configurations files and example date to form a build-, test- and development environment for *System Transparency*.
The source code of the various components resides in the appropriate repositories. Detailed information about the project itself can be found at https://docs.system-transparency.org.

Each folder contains an own README.md describing its content and the purpose of the files.

## Table of Content
* `configs/` : configuration of operating systems
* `deploy/` : scripts and files to build firmware binaries
* `keys/` : example certificates and signing keys
* `operating-system/` : folders including scripts ans files to build reproducible operating systems
* `stboot/` : scripts and files to build stboot bootloader from source 
* `stconfig/`: scripts and files to build the bootloader's configuration tool from source

## Scripts
#### `run.sh`
This script is the global entry point to build up or update the environment.
It runs a dependency check and prompts you to execute all other necessary scripts and thereby leads through the whole setup process. Each step can be run, run with special options where applicable or skipped. In this way you can also only renew certain parts of the environment.
Run each step when executing for the first time. Some scripts need root privileges.

#### `start_qemu_mixed-firmware.sh`
This script is invoked by `run.sh`. It will boot up *qemu* to test the system. All output is printed to the console.
Use `ctrl+a` , `x` to terminate.

