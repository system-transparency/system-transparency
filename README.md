# System Transparency Tooling

This repository contains tooling, configuration files and demos to form a build-, test- and development environment for [System Transparency](https://www.system-transparency.org/).

_stboot_ is System Transparency Project’s official bootloader. It is a [LinuxBoot](https://www.linuxboot.org/) distribution based on [u-root](https://github.com/u-root/u-root). The source code for stboot can be found at https://git.glasklar.is/system-transparency/core/stboot.

With System Transparency, all OS-related artifacts including the userspace are bundled together in a signed [OS Package](#os-package). The core idea is that stboot verifies this OS package before booting.

For getting going right away, follow the instructions in the [demo section](#demonstrating-the-whole-thing).

For a step-by-step guide with more explanatory text, see the [guide](doc/guide.md).


# Prerequisites

Your machine should run a Linux system (regularly tested with Ubuntu 20.04 LTS, known to have been working on Debian 11 and Fedora 38).

## Golang

Make sure you have at least go1.17 running on your system. See [here](https://go.dev/doc/install) for installation.


## Environment

The System Transparency Repository provides a `setup.env` file meant to be sourced in a shell to load the build environment. It installs the latest version of [Task](https://taskfile.dev/), if not already installed, and configures a separate GOPATH to prevent conflicts. To load and unload the environment depending on the current directory, it is recommended to use [direnv](https://direnv.net/). See [direnv Basic Installation](https://direnv.net/#basic-installation) to see how to properly setup direnv for your shell.

After restarting your shell, you can enable direnv for this repository:

```bash
echo "source setup.env" > .envrc
direnv allow
```

As an alternative, you can load the environment directly without direnv:

```bash
source setup.env
```

However, this is only recommended in CI workflows since it makes the environment changes persistent in your current shell.


# Demonstrating the whole thing

## Demo 1: ST-booting an OS package downloaded over HTTPS

To see System Transparency in action you first need a signed OS package to be loaded by stboot:

```bash
task demo:ospkg
```

Then let task build a complete stboot ISO image:

```bash
task iso
```

Finally, enjoy stboot in action:

``` bash
task qemu:iso
```

### Notes

- Username/password for the booted Ubuntu is stboot/stboot.

- The ISO image (located in `out/stboot.iso`) is sending all console
  output to the first serial port (`/dev/ttyS0`), so it probably won't
  work right away on your laptop or server system.

- To quit QEMU: `C-a x`.

## Demo 2: including stprov in stboot's initramfs

``` bash
task iso-provision qemu:iso
```

stboot will enter provision mode since it cannot find enough host configuration and trust policy. You can now provision the system by running stprov.

``` bash
stprov remote static -h myhost -i 10.0.2.10/27 -g 10.0.2.2 -A
```

This should result in EFI NVRAM variables (backed by the file `out/artifacts/OVMF_VARS.fd`) being set up so that the next boot do **not** enter provision mode but instead uses the provisioned host configuration.

Shut down the provisioned system.

``` bash
shutdown
```

The next time stboot starts with this EFI NVRAM it will find proper host configuration and use that information to configure the network and find an OS package to fetch, verify and boot.

(In the current version of stboot (v0.2.0) the boot mode must be [initramfs](#initramfs-boot) for doing provisioning the way we're doing here. This means that an stprov ISO/UKI image will not be useful for fetching OS packages over the network. This lmitation will be removed in a future stboot release.)

To get back to provisioning, simply remove the file backing the EFI NVRAM and boot the ISO again.

```
rm out/artifacts/OVMF_VARS.fd
task qemu:iso
```

### Tips and tricks

- To quit QEMU: `C-a x`.


# OS Package
An OS package consists of an archive file (ZIP) and a [descriptor file][] (JSON). The archive contains the boot files (kernel, initramfs, etc.) and the descriptor file contains the signatures for the archive and other metadata.

OS packages can be created and managed with the `stmgr` tool. Source code for stmgr can be found at https://git.glasklar.is/system-transparency/core/stmgr/.

Once you have an OS kernel and an initramfs file containing the userspace, create an OS package out of it:
``` bash
# Create a new OS package
stmgr ospkg create -kernel=<your_OS_kernel> -initramfs=<your_OS_initramfs>
# Sign the OS package (multiple times)
stmgr ospkg sign -key=<your.key> -cert=<your.cert> -ospkg=<OS package>

# See help for all options
stmgr ospkg -help
```

[descriptor file]: https://pkg.go.dev/system-transparency.org/stboot@v0.2.0/ospkg#Descriptor

# System Configuration

The behavior of stboot is determined by two separate JSON documents:
- [trust policy][], and
- [host configuration][]

The trust policy specifies how many valid signatures are required for an OS package and what [boot mode](#boot-modes) is used.

The host configuration contains
* enough information to set up what's needed to fetch the OS package, typically network configuration,
* an OS package pointer, and
* identity data unique to each provisioned system.

Information on host configuration autodetection can be found [here](https://pkg.go.dev/system-transparency.org/stboot@v0.2.0/host#ConfigAutodetect)

[trust policy]: https://pkg.go.dev/system-transparency.org/stboot@v0.2.0/trust#Policy
[host configuration]: https://pkg.go.dev/system-transparency.org/stboot@v0.2.0/host#Config

## Boot Modes
stboot can fetch OS packages from different sources. The fetching mechanism is determined by the trust policy.

The location of the OS package is defined by the OS package pointer in the host config. The format of the OS package pointer needs to satisfy the requirements of the choosen fetching mechanism.

stboot will do string replacement on `$ID` and `$AUTH` in the OS package pointer using the values `identity` and `authentication` from the host configuration.

### Network Boot
Network boot can be configured using either DHCP or a static network configuration. In the case of a static network, stboot uses IP address, netmask, default gateway, and DNS server from the host configuration.

OS package server communication:
* The HTTPS root certificates are stored in the LinuxBoot initramfs
    * File name: `/etc/https_roots.pem`
    * Uses the roots in https://letsencrypt.org/certificates/ per default

The OS package pointer:
* Is a URL with method HTTP or HTTPS
* The URL serves up the [OS package descriptor](#os-package)

Fetching an OS package goes like this:
* Download the OS package descriptor (JSON file)
* Extract the OS package URL
* Check the filename part of the OS package URL (must be `.zip`)
* Download the OS package

### Initramfs Boot
Initramfs boot expects the OS package artifacts to be included inside the initramfs.

The OS package pointer:
* Is a filename like `my-ospkg.json`

The OS package will then be loaded from:
* Descriptor: `/ospkg/my-ospkg.json`
* Archive: `/ospkg/my-ospkg.zip`

## Signature Verification

stboot verifies the signatures before opening an OS package.

SHA256 must be used to hash the OS package ZIP archive file. The signature must be calculated from the resulting hash.

An OS package is signed using one or more X.509 signing certificates.

The root certificate for the signing certificates is packed into the LinuxBoot initramfs at `/etc/trust_policy/ospkg_signing_root.pem`. Also, the minimum number of signatures required resides in the initramfs in `etc/trust_policy/trust_policy.json`. Ed25519 is recommended for the root certificate as well as the signing certificates.

Two files are involved, the OS package itself and a corresponding descriptor file:
* `SOMENAME.zip` (archive file)
* `SOMENAME.json` (descriptor file)

The verification process in stboot:
* Validate the document format.
* For each signature certificate tuple:
    * Validate the certificate against the root certificate.
        * Only check validity bounds and if the certificate is chained to the trusted root certificate.
    * Check for duplicate X.509 certificates.
    * Verify signature.
    * Increase count of valid signatures.
* Check if the number of successful signatures is enough.
