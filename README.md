# System Transparency Tooling

This repository contains tooling, configuration files and, demos to form a build-, test- and development environment for _System Transparency_.

_stboot_ is System Transparency Project’s official bootloader. It is a [LinuxBoot](https://www.linuxboot.org/) distribution based on [u-root](https://github.com/u-root/u-root). The source code of stboot can be found at https://git.glasklar.is/system-transparency/core/stboot.

With System Transparency, all OS-related artifacts including the userspace are bundled together in a signed [OS Package](#OS-Package). The core idea is that stboot verifies this OS package before booting.


# Prerequisites
Your machine should run a Linux system (tested with Ubuntu and 20.04.2 LTS).

## Task

[Task](https://taskfile.dev) is a task runner/build tool that aims to be simpler and easier to use than, for example, [GNU Make](https://www.gnu.org/software/make/). It provides remarkable documentation and uses a simple YAML schema to define tasks. For more information, go to https://taskfile.dev or run `task --help`.

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

## Build Dependencies

This is work in progress.

System Transparency requires some dependencies to build the complete installation image. You can check for missing dependencies:

```bash
task deps:check
```

In addition, it is possible to install all dependencies on Debian based environments (tested with Ubuntu 18.04.2 LTS and 20.04.2 LTS):

```bash
task deps:install
```
`Note: user requires privileges via sudo`


## Demo Files

To see System Transparency in action you need a signed OS package to be loaded by stboot, it is possible to create an Image for demo purposes.

First, generate all required keys and certificates for the signature verification:

```bash
task demo:keygen
```

Afterward, an example OS package can be built with:

```bash
task demo:ospkg
```

It builds an example Debian OS image with [debos](https://github.com/go-debos/debos) and uses stmgr to convert it to an OS package.

```bash
task demo:server &
```

Will start a HTTP server in the background where stboot can read the OS package from.

# Installation
To bring System Transparency to your systems, you need to deploy an installation image. Run the following to create an image.
See [Deployment](#Deployment) for the supported scenarios.

## Configure

To generate a default configuration:

```bash
task config
```

The config file `st.config` contains all available configuration variables. Take a look at the descriptions provided in this file for details.

## Build
```bash
# build stboot ISO image
task iso
```

## Test
``` bash
# run stboot ISO image
task qemu:iso
```

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


# System Configuration

See package `opts` at [stboot code](https://git.glasklar.is/system-transparency/core/stboot).

# Features

## Network Boot
Network boot can be configured using either DHCP or a static network configuration. In the case of a static network, stboot uses IP address, netmask, default gateway, and DNS server from `host_configuration.json`.

Provisioning Server Communication:
* The HTTPS root certificates are stored in the LinuxBoot initramfs
    * File name: `/etc/https_roots.pem`
    * Use https://letsencrypt.org/certificates/ roots as default.

Provisioning URLs:
* If multiple provisioning URLs are present in host_configuration, try all, in order.
* The user must specify HTTP or HTTPS in the URL.
* stboot will do string replacement on $ID and $AUTH using the values from `host_configuration.json`:
    * e.g. https://provisioning.foo.net/api/v1/?id=$ID&auth=$AUTH 
    * e.g. https://provisioning.bar.net/api/v1/$ID

These URLs are supposed to serve the OS package descriptor.

For each provisioning server URL in `host_configuration.json`:
* Try downloading the OS package descriptor (JSON file).
* Extract the OS package URL.
* Check the filename in the OS package URL. (must be `.zip`)
* Try downloading the OS package

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


