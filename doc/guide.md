# How to put together a bootable image

This document will walk you through all steps needed in order to produce a bootable image -- ISO or UKI -- for booting your servers. This will be done in the form of showing the output from a few selected task runners, explaining what needs to be done and in which order. We will be filtering out some of the go tooling output and annotate the output to make it easier to read. 

Please note that the task runners provided are meant for a) simple demos and b) internal automated testing. They do not provide a stable interface suitable for basing your own build infrastructure on.

## Overview

At the heart of a bootable image is an initramfs containing [stboot][], the boot loader, and its configuration. You will also need a Linux kernel to include in the boot image.

The initramfs will have to contain numerous configuration bits and pieces, influencing different aspects of the boot process. We will be using two programs to put it all together, [stmgr][] and [u-root][].

![components][]

[stboot]: https://git.glasklar.is/system-transparency/core/stboot
[stmgr]: https://git.glasklar.is/system-transparency/core/stmgr
[u-root]: https://github.com/u-root/
[components]: stboot.png "Components graph"

## Setting up the build environment

We will be starting a new shell that you can exit from when you're done, to get rid of the shell environment state set up by this procedure.


``` bash
$ bash -
$ . setup.env
```


## Building build dependencies
Download and build everything needed for future build steps by running **task toolchain**:

``` bash
leguin:system-transparency% task toolchain
task: [go:update] rm -rf cache/go/bin
task: [go:install u-root] GOPATH=/path/to/system-transparency/cache/go go install -ldflags "" github.com/u-root/u-root@v0.10.0
task: [go:install sthsm] GOPATH=/path/to/system-transparency/cache/go go install -ldflags "" git.glasklar.is/system-transparency/project/sthsm/cmd/mgmt@e428dbc
task: [go:install task] GOPATH=/path/to/system-transparency/cache/go go install -ldflags "" github.com/go-task/task/v3/cmd/task@latest
task: [go:install stmgr] GOPATH=/path/to/system-transparency/cache/go go install -ldflags "" system-transparency.org/stmgr@v0.2.0
task: [go:install stprov] GOPATH=/path/to/system-transparency/cache/go go install -ldflags "" system-transparency.org/stprov/cmd/stprov@v0.1.1
task: [get github.com/u-root/u-root] GOPATH=/path/to/system-transparency/cache/go go get -d github.com/u-root/u-root/...
task: [go:checkout github.com/u-root/u-root@v0.10.0] git -C cache/go/src/github.com/u-root/u-root fetch --quiet
task: [go:checkout github.com/u-root/u-root@v0.10.0] git -C cache/go/src/github.com/u-root/u-root checkout --quiet v0.10.0
task: [get system-transparency.org/stboot] GOPATH=/path/to/system-transparency/cache/go go get -d system-transparency.org/stboot/...
```

Some of the installed packages are optional for this guide but you will need the following ones for sure:
- stmgr
- stboot
- u-root


## Generating signing keys

In order to compile an initramfs, you will need a set of signing keys and accompanying X.509 certificates and their root cert. This is because the initramfs will contain the root cert, as a trust root for verifying OS packages.

If you don't already have a PKIX CA and signing keys with certs, you can use the `stmgr keygen certificate` to set this up.
We will run once `stmgr keygen certificate` to create the CA cert and once more per key and cert that we generate.

The **demo:keygen** task runner creates a CA and two signign keys:

``` bash
$ task demo:keygen
[demo:keygen] cache/go/bin/stmgr keygen certificate -isCA -certOut=out/keys/example_keys/root.cert -keyOut=out/keys/example_keys/root.key
[demo:keygen] cache/go/bin/stmgr keygen certificate -rootCert=out/keys/example_keys/root.cert -rootKey=out/keys/example_keys/root.key -certOut=out/keys/example_keys/signing-key-1.cert -keyOut=out/keys/example_keys/signing-key-1.key
[demo:keygen] cache/go/bin/stmgr keygen certificate -rootCert=out/keys/example_keys/root.cert -rootKey=out/keys/example_keys/root.key -certOut=out/keys/example_keys/signing-key-2.cert -keyOut=out/keys/example_keys/signing-key-2.key
```


## Building an stboot initramfs and putting it into an ISO

The **iso** task runner does a lot of things:
- copies a prebuilt linux kernel in place for later inclusion in the ISO
- runs `stmgr hostconfig check` and `stmgr trustpolicy check` on config example templates
- runs `u-root -build=bb` with a long list of input arguments defining the initramfs to be built
- compresses the resulting cpio archive -- this is the initramfs
- runs `stmgr uki create -format iso` to put together the bootable ISO image

The resulting file is **out/stboot.iso**.

```
$ task iso
task: [linux:kernel-prebuilt] cp contrib/linuxboot.vmlinuz out/artifacts/stboot.vmlinuz
task: [hostconfig-network] cache/go/bin/stmgr hostconfig check '{
  "network_mode":"dhcp",
  "host_ip":null,
  "gateway":null,
  "dns":null,
  "network_interfaces":null,
  "ospkg_pointer": "http://10.0.2.2:8080/os-pkg-example-ubuntu20.json",
  "identity":null,
  "authentication":null,
  "timestamp":null,
  "bonding_mode": "",
  "bond_name": ""
}' > out/artifacts/host_config.json
task: [trustpolicy] cache/go/bin/stmgr trustpolicy check '{
  "ospkg_signature_threshold": 2,
  "ospkg_fetch_method": "network"
}' > out/artifacts/trust_policy.json
[initramfs:build] Building initramfs via u-root with stboot as init process
[initramfs:build] Including files:
[initramfs:build] - out/keys/example_keys/root.cert:etc/trust_policy/ospkg_signing_root.pem
[initramfs:build] - contrib/initramfs-includes/isrgrootx1.pem:etc/ssl/certs/isrgrootx1.pem
[initramfs:build] - out/artifacts/host_config.json:etc/host_configuration.json
[initramfs:build] - out/artifacts/trust_policy.json:etc/trust_policy/trust_policy.json
task: [initramfs:build] GOPATH=/path/to/system-transparency/cache/go cache/go/bin/u-root -build=bb -uinitcmd="stboot -loglevel=d" -defaultsh="" -uroot-source ./cache/go/src/github.com/u-root/u-root -o out/artifacts/initramfs:incl-hostconfig.cpio.tmp -files out/keys/example_keys/root.cert:etc/trust_policy/ospkg_signing_root.pem -files contrib/initramfs-includes/isrgrootx1.pem:etc/ssl/certs/isrgrootx1.pem -files out/artifacts/host_config.json:etc/host_configuration.json -files out/artifacts/trust_policy.json:etc/trust_policy/trust_policy.json  github.com/u-root/u-root/cmds/core/init system-transparency.org/stboot

[initramfs:build] 23:33:27 Disabling CGO for u-root...
[initramfs:build] 23:33:27 Build environment: GOARCH=amd64 GOOS=linux GOROOT=/usr/lib/golang GOPATH=/path/to/system-transparency/cache/go CGO_ENABLED=0
[initramfs:build] 23:33:27 WARNING: You are not using one of the recommended Go versions (have = go1.20.4, recommended = [go1.17]).
[initramfs:build]                       Some packages may not compile.
[initramfs:build]                       Go to https://golang.org/doc/install to find out how to install a newer version of Go,
[initramfs:build]                       or use https://godoc.org/golang.org/dl/go1.17 to install an additional version of Go.
[initramfs:build] 23:33:27 NOTE: building with the new gobusybox; to get the old behavior check out commit 8b790de
[initramfs:build] 23:33:33 Successfully built "out/artifacts/initramfs:incl-hostconfig.cpio.tmp" (size 7289992).
task: [initramfs:build] mv out/artifacts/initramfs:incl-hostconfig.cpio.tmp out/artifacts/initramfs:incl-hostconfig.cpio
task: [initramfs:generic] gzip -kf out/artifacts/initramfs:incl-hostconfig.cpio
task: [initramfs:generic] mv out/artifacts/initramfs:incl-hostconfig.cpio.gz out/artifacts/stboot.cpio.gz
task: [iso] cache/go/bin/stmgr uki create -format iso -out 'out/stboot.iso' -kernel=out/artifacts/stboot.vmlinuz -initramfs=out/artifacts/stboot.cpio.gz
```

## Building an OS package

The **demo:ospkg** task runner puts together an OS package by
- downloading a prebuilt Ubuntu kernel and initramfs,
- running `stmgr ospkg create`, and
- running `stmgr ospkg sign` to sign the OS package

The resulting files are **out/ospkgs/os-pkg-example-ubuntu20.{json,zip}** which should now be copied to a web server from which stboot will download them. The URL under which the JSON file is served must be what is found in the stboot host configuration entry **ospkg_pointer**.

```
$ task demo:ospkg
task: [demo:ubuntu-prebuilt] curl -L -o cache/debos/ubuntu-focal-amd64.cpio.gz https://github.com/system-transparency/example-os/releases/download/v0.1/ubuntu-focal-amd64.cpio.gz
task: [demo:ubuntu-prebuilt] curl -L -o cache/debos/ubuntu-focal-amd64.vmlinuz https://github.com/system-transparency/example-os/releases/download/v0.1/ubuntu-focal-amd64.vmlinuz
task: [demo:ospkg] cache/go/bin/stmgr ospkg create -out 'out/ospkgs/os-pkg-example-ubuntu20.zip' -label='System Transparency Test OS' -kernel=cache/debos/ubuntu-focal-amd64.vmlinuz -initramfs=cache/debos/ubuntu-focal-amd64.cpio.gz -cmdline='console=tty0 console=ttyS0,115200n8 rw rdinit=/lib/systemd/systemd' -url=http://10.0.2.2:8080/os-pkg-example-ubuntu20.zip
task: [demo:ospkg] for i in {1..2}; do cache/go/bin/stmgr ospkg sign -key=out/keys/example_keys/signing-key-$i.key -cert=out/keys/example_keys/signing-key-$i.cert -ospkg out/ospkgs/os-pkg-example-ubuntu20.zip; done
```
