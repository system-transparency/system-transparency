# System Transparency Tooling

This repository contains tooling, configuration files and demos to form a build-, test- and development environment for _System Transparency_.

_stboot_ is System Transparency Project’s official bootloader. It is a [LinuxBoot](https://www.linuxboot.org/) distribution based on [u-root](https://github.com/u-root/u-root). The source code of stboot can be found at https://git.glasklar.is/system-transparency/core/stboot.

With System Transparency, all OS-related artifacts including the userspace are bundled together in a signed [OS Package](#OS-Package). The core idea is that stboot verifies this OS package before booting.


# Prerequisites
Your machine should run a Linux system (tested with Ubuntu and 20.04.2 LTS).

## Golang

Make sure you have at least go1.17 running on your system. See [here](https://go.dev/doc/install) for installation.

## Task

[Task](https://taskfile.dev) is a task runner or build tool, respectively. It aims to be simpler and easier to use than, for example, [GNU Make](https://www.gnu.org/software/make/). It provides remarkable documentation and uses a simple YAML schema to define tasks. For more information, go to https://taskfile.dev or run `task --help`.

To see all available tasks:

```bash
task -l
```

## Environment

The System Transparency Repository provides a `setup.env` file to load the build environment. It installs the latest version of [Task](https://taskfile.dev) and configures a separate GOPATH to prevent any conflicts. To load and unload the environment depending on the current directory, it is recommended to use [direnv](https://direnv.net/). See [Basic Installation](https://direnv.net/#basic-installation) to see how to properly setup direnv for your shell.
After restarting your shell, you can enable direnv for the repository:

```bash
echo "source setup.env" > .envrc
direnv allow
```

As an alternative, you can load the environment directly without direnv:

```bash
source setup.env
```

However, this is only recommended on CI workflows since it makes the environment changes persistent in your current shell session.


## Demo

To see System Transparency in action you need a signed OS package to be loaded by stboot.

```bash
task demo:ospkg
```

Now let task build an complete stboot image for you:

```bash
task iso
```

Finally, start a webserver in the background providing the OS package and enjoy stboot in action:
``` bash
task demo:server &
task qemu:iso
```
(Login to the booted Ubuntu: user: stboot, pw: stboot)


## Demo 2, including stprov in an os-pkg, in the initramfs
``` bash
task iso-provision qemu:iso
```

Once stboot has entered provision mode, because it cannot find enough
host config and trust policy, try provisioning the machine by running
stprov:

``` bash
stprov remote static -h x -i 10.0.2.10/27 -g 10.0.2.2 -A
```

This should result in out/artifacts/OVMF_VARS.fd being set up so that
the next boot do not enter provision mode.


# Installation

TBD. 

However, the log of task in the demos delivers detailed information on the executed commands. You can adapt these to your need.


# OS-Package
An OS package consists of an archive file (ZIP) and descriptor file (JSON). The archive contains the boot files (kernel, initramfs, etc.) and the descriptor file contains the signatures and other metadata.

OS packages can be created and managed with the _stmgr_ tool. Source code of stmgr: https://git.glasklar.is/system-transparency/core/stmgr

Once you have an OS kernel & initramfs containing the userspace, create an OS package out of it:
``` bash
# Create a new OS package
stmgr ospkg create -kernel=<your_OS_kernel> -initramfs=<your_OS_initramfs>
# Sign the OS package (multiple times)
stmgr ospkg sign -key=<your.key> -cert=<your.cert> -ospkg=<OS package>

# See help for all options
stmgr -help
```

# System Configuration

See package `opts` at [stboot code](https://pkg.go.dev/system-transparency.org/stboot@v0.2.0/host#Config).
Information on host config autodetection can be found [here](https://pkg.go.dev/system-transparency.org/stboot@v0.2.0/host#ConfigAutodetect)

# Features

## Boot Modes

stboot can fetch OS packages from different sources. The fetching mechanism is determined by the trust policy.
The location of the OS package is defined by the OS package pointer in the host config. The format of the OS package pointer needs to setisfy the requirements of the choosen fetching mechanism.

stboot will do string replacement on $ID and $AUTH in the OS package pointer using the values _identity_ and _authentication_ from the host configuration.

### Network Boot
Network boot can be configured using either DHCP or a static network configuration. In the case of a static network, stboot uses IP address, netmask, default gateway, and DNS server from `host_configuration.json`.

Provisioning Server Communication:
* The HTTPS root certificates are stored in the LinuxBoot initramfs
    * File name: `/etc/https_roots.pem`
    * Use https://letsencrypt.org/certificates/ roots as default.

OS package pointer:
* Expect a comma separated list of URLs
* If multiple URLs are present, try all, in order.
* The user must specify HTTP or HTTPS in the URL.

These URLs are supposed to serve the OS package descriptor.

For each provisioning server URL in `host_configuration.json`:
* Try downloading the OS package descriptor (JSON file).
* Extract the OS package URL.
* Check the filename in the OS package URL. (must be `.zip`)
* Try downloading the OS package

### Initramfs Boot
Initramfs boot expects the OS package artifacts to be included inside the initramfs.

OS package pointer:
* Expect a filename like _my-ospkg.json_

The OS package will then be loaded from:
* Descriptor: `/ospkg/my-ospkg.json`
* Archive: `/ospkg/my-ospkg.zip`

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


