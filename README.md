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
* Docker for building the a reproducible debian buster kernel and initramfs.


## Setup for image

Roughly the installation is seperated in two parts. 
The upper part contains the instructions you need to build the image for QEMU. This image contains a SysLinux with a custom u-root initramfs including STBoot boot loader.
The lower part shows how to set up a boot configuration which will be uploaded to a provisioning server and later downloaded inside QEMU for testing.

Every step concludes that you start in the base directory of the repository. You need to cd inside the different directories and execute the scripts from there.


### 0) Download repository
```
git clone https://github.com/system-transparency/system-transparency.git
```

### 1) U-Root
U-root is a generator for initramfs which already includes some usefull commands
For further information see https://github.com/u-root/u-root
```
go get -u github.com/u-root/u-root
```

### 2) Get u-roots stboot branch
STboot is under development, so it is not in the master tree yet. It must be checked out separatly:
```
cd $HOME/go/src/u-root/u-root
git checkout --track origin/stboot
```

### 3) Build initramfs for image.
Inside system-transparency repository base directory run:
```
cd stboot
./install-u-root.sh
./make_initramfs.sh
```

### 3) Build image for manual deployment/QEMU
```
./build_image.sh
```
This script will build an image based on SysLinux but without initramfs. 

### 4) Merge image and initramfs
Run:
```
cd deploy/image
./mv_initrd_to_image.sh
./mv_netvars_to_image.sh
```

### 5) Test the image in QEMU
Run:
```
./start_qemu_image.sh
```

QEMU should start up and will drop you into a shell. You can use some shell commands like ls, cd, etc. and move around in the file system and explore a little.

## Setup for boot config creation

Now you have a running QEMU image but no boot configuration to execute. The following part will show you how to built a boot configuration and upload it to your provisioning server.

### 1) STConfig tool
The STconfig tool is used to create the boot config zip-archive which later will be downloaded during the boot process by `stboot`
Only the first time you need to run this script to initialize the workspace:
```
cd stconfig
./install_stconfig.sh
```
This will place a folder named 'config/' inside you repository. The config folder is marked in the .gitignore file.

### 2) Build a reproducible debian linux kernel and initramfs

First of all you need docker. For debian/ubuntu host:  
```
sudo apt-get install docker.io
```

After you installed docker, just run the following script:
```
cd remote-os/debian
./build_os_docker.sh
```
The script will create a new folders configs/debian. Inside this, three folder are made as well.
A docker image will be created, based on the Dockerfile and execute the container.
The container will create a new folder ./out  and copies the built kernel and initramfs inside.
From there, kernel and initramfs files are copied to subfolders kernel and initrds in

```
./configs/debian/*
```

It also creates the manifest.json inside with the necessary paths.

### 3) Generating boot config


Inside the configs/debian folder you'll find three folders: kernels, initramfs and signing.

The manifest.json file is used by the 'stconfig' tool for the creation of the boot configuration.
You need to check the paths for kernel, initramfs and rootCert.
Inside the signing folder you'll find the 'create-keys.sh'
Run it with:
```
./crete-keys.sh
```
Now you have several RSA keys and certificates which can be used to build and sign a boot config for testing.
Make sure, the name and path of the root certificate matches inside the 'manifest.json'.

```
stconfig create -o path/for/output.zip path/to/manifest.json
```
### 4) Sign boot config 
This is one of the key elements of STBoot. Every boot configuration has to be signed by a trusted and known RSA-Identity.
```
stconfig sign path/to/stboot.zip path/to/privatekey.key path/to/certificate.cert
```
Right now, STBoot require a triple signed boot configuration, so you need to sign your test configuration with key1 & cert1, key2 & cert2, key3 & cert3 or a different combination but at least three.

### 5) Upload your boot configuration to provisioning server
The triple signed boot configuration archive can be uploaded by running:
```
./upload_config.sh
```
SSH key of user must be deployed on provisioning server.

## Run everything at once
To run everything at once you can run:
```
./run_all.sh
```
The interactive script will ask you for every step. Look inside run_all.sh and the other scripts to understand what they do in detail.
Have fun :)

# Acknowledgement
Thanks to the tails project for their reproducible build debian system. Thanks to the OpenWrt project for the source date epoch functions.