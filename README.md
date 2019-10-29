# System-Transparency

This repository represents the idea of a transparent and verifiable boot process.
Its goal is to give you the tools necessary for building an environment to boot from.

At the moment there are two ways to deploy this. 
1. ST-Coreboot  
Coreboot needs to be deployed as firmware. Its payload must be a linux kernel and an initramfs with stboot included.

2. U-Root also can be deployed inside an image to a server via dd command manually.  
This method is used for testing with QEMU.

# Test environment for STBoot/Systemboot
## Prerequisites
* Linux system (tested with Ubuntu 18.04.2 LTS (Bionic Beaver) / Kernel 4.15.0-47-generic
* Golang v 1.12 (see [install Go](https://golang.org/doc/install#install )
	* make sure to also create a workspace at `$HOME/go` (see [test Go](https://golang.org/doc/install#testing )
	* make sure `$HOME/go/bin` and `/usr/local/go/bin` or '/usr/bin/go are added to `PATH` environment variable
* QEMU emulator (tested with version 2.11.1)
* Provisioning server with https-request capability
* ssh access to root@yourserver.test (your 'provisioning server')
* Virtual machine with Debian-Buster for creating a reproducible debian build (native and over linux containers).


## Installation

#### 0) download repository
```
git clone https://github.com/system-transparency/system-transparency.git
```

#### 1) Build image for QEMU
```
./build_image.sh
```
This script will build an image you can run inside QEMU. Basically is SysLinux with STBoot.

#### 2) U-Root
U-root is a generator for initramfs which already includes some usefull commands
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
#### 4) STConfig tool
The STconfig tool is used to create the boot config zip-archive which later will be downloaded during the boot process by `stboot`
```
cd $HOME/go/src/u-root/u-root/cmds/configtool
go install
```
This will install the conigtool into `$HOME/go/bin`

#### 5) Generating boot config
Only the first time you need to run this script to initialize the workspace:
```
./init_workspace.sh
```
This will place a folder named 'stconfig/testing' inside you repository.
Inside this folder you'll find a debian linux kernel, initramfs, manifest.json and RSA keys and certificates which can be used to build and sign a boot config for testing.
```
stconfig create -o path/for/output.zip path/to/manifest.json
```
#### 6) Sign boot config 
This is one of the key elements of STBoot. Every boot configuration has to be signed by a trusted and known RSA-Identity.
```
stconfig sign path/to/stboot.zip path/to/privatekey.key path/to/certificate.cert
```
Right now, STBoot require a triple signed boot configuration, so you need to sign your test configuration with key1 & cert1, key2 & cert2, key3 & cert3

#### 7) Upload your boot configuration to provisioning server
The triple signed boot configuration archive can be uploaded by running:
```
./upload_config.sh
```
SSH key of user must be deployed on provisioning server.

## Build a reproducible debian linux kernel and initramfs

#### Set up environment
First of all you need a running debian system. Native or inside a virtual machine like VirtualBox (https://www.virtualbox.org/).  
On the virtual machine you need to clone the repository for access to the scripts.
After setting up the repository run as root or sudo:
```
./system-transparency/remote-os/debian/setup.sh
```
This script will install all necessary packages for debian you'll need to creat a reproducible kernel.
After that, just run the following script:
```
./system-transparency/remote-os/debian/build.sh
```

# Acknowledgement
Thanks to the tails project for their reproducible build debian system. Thanks to the OpenWrt project for the source date epoch functions.