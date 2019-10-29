# System-Transparency

This repository represents the idea of a transparent and verifiable boot process.
Its goal is to give you the tools necessary for building an environment to boot from.

At the moment there are two ways to deploy this. 
1. ST-Coreboot
Coreboot needs to be deployed as firmware. Its payload needs to be u-root with stboot bootloader.
2. U-Root also can be deployed inside an image to a server via dd command manualy.
This is image can be used for testing with QEMU.

# Test environment for STBoot/Systemboot
## Prerequisites
* Linux system (tested with Ubuntu 18.04.2 LTS (Bionic Beaver) / Kernel 4.15.0-47-generic
* Golang v 1.12 (see [install Go](https://golang.org/doc/install#install )
	* make sure to also create a workspace at `$HOME/go` (see [test Go](https://golang.org/doc/install#testing )
	* make sure `$HOME/go/bin` and `/usr/local/go/bin` or '/usr/bin/go are added to `PATH` environment variable
* QEMU emulator (tested with version 2.11.1)
* ssh access to root@yourserver.test (your 'provisioning server')
* Virtual machine with Debian-Buster for creating a reproducible debian build (native and over lxc).
* 

## Installation

#### 0) download repository
```
git clone https://github.com/system-transparency/system-transparency.git
```

#### 1) Build image for QEMU
```
./build_image.sh
```
This script will build an image you can run inside QEMU. Basically is SysLinux with u-root with STBoot boot loader capability.

#### 2) U-Root
U-root the initramfs generator itself which already includes some usefull commands
For further information see https://github.com/u-root/u-root
```
go get -u github.com/u-root/u-root
```

#### 3) get u-root stboot branch
STboot is under development, so it is not in the master tree yet. It must be checked out separatly:
```
cd $HOME/go/src/u-root/u-root
git checkout --track origin/stboot
```
#### 4) configtool
The configtool is used to create the boot config zip-archive which later will be downloaded during the boot process by `stboot`
```
cd $HOME/go/src/u-root/u-root/cmds/configtool
go install
```
This will install the conigtool into `$HOME/go/bin`
