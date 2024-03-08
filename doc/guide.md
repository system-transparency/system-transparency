# How to put together a bootable image

This document will walk you through all steps needed in order to produce a bootable image -- ISO or UKI -- for booting your servers. This will be done in the form of showing the output from a few selected task runners, explaining what needs to be done and in which order. We will be filtering out some of the go tooling output and annotate the output to make it easier to read. 

Please note that the task runners provided are meant for a) simple demos and b) internal automated testing. They do not provide a stable interface suitable for basing your own build infrastructure on.

## Overview

At the heart of a bootable image is an initramfs containing [stboot][] and its configuration. You will also need a Linux kernel to include in the boot image.

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
task: [go:clean] cd /path/to/system-transparency/bin && rm -f u-root stboot stmgr stprov mgmt stauth
task: [go:install stmgr] GOBIN=/path/to/system-transparency/bin go install -ldflags "" system-transparency.org/stmgr
task: [go:install u-root] GOBIN=/path/to/system-transparency/bin go install -ldflags "" github.com/u-root/u-root
task: [go:install sthsm] GOBIN=/path/to/system-transparency/bin go install -ldflags "" git.glasklar.is/system-transparency/project/sthsm/cmd/mgmt
task: [go:install stprov] GOBIN=/path/to/system-transparency/bin go install -ldflags "" system-transparency.org/stprov/cmd/stprov
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
[demo:keygen] bin/stmgr keygen certificate -isCA -certOut=out/keys/example_keys/root.cert -keyOut=out/keys/example_keys/root.key
[demo:keygen] bin/stmgr keygen certificate -rootCert=out/keys/example_keys/root.cert -rootKey=out/keys/example_keys/root.key -certOut=out/keys/example_keys/signing-key-1.cert -keyOut=out/keys/example_keys/signing-key-1.key
[demo:keygen] bin/stmgr keygen certificate -rootCert=out/keys/example_keys/root.cert -rootKey=out/keys/example_keys/root.key -certOut=out/keys/example_keys/signing-key-2.cert -keyOut=out/keys/example_keys/signing-key-2.key
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
task: [hostconfig-network] bin/stmgr hostconfig check '{
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
task: [trustpolicy] bin/stmgr trustpolicy check '{
  "ospkg_signature_threshold": 2,
  "ospkg_fetch_method": "network"
}' > out/artifacts/trust_policy.json
[initramfs:build] Building initramfs via u-root with stboot as init process
[initramfs:build] Including files:
[initramfs:build] - out/keys/example_keys/root.cert:etc/trust_policy/ospkg_signing_root.pem
[initramfs:build] - contrib/initramfs-includes/isrgrootx1.pem:etc/trust_policy/tls_roots.pem
[initramfs:build] - out/artifacts/host_config.json:etc/host_configuration.json
[initramfs:build] - out/artifacts/trust_policy.json:etc/trust_policy/trust_policy.json
task: [initramfs:build] GOBIN=/path/to/system-transparency/bin bin/u-root -build=bb -uinitcmd="stboot -loglevel=d" -defaultsh="" -uroot-source ./cache/u-root -o out/artifacts/initramfs:incl-hostconfig.cpio.tmp -files out/keys/example_keys/root.cert:etc/trust_policy/ospkg_signing_root.pem -files contrib/initramfs-includes/isrgrootx1.pem:etc/trust_policy/tls_roots.pem -files out/artifacts/host_config.json:etc/host_configuration.json -files out/artifacts/trust_policy.json:etc/trust_policy/trust_policy.json  github.com/u-root/u-root/cmds/core/init system-transparency.org/stboot

[initramfs:build] 23:33:27 Disabling CGO for u-root...
[initramfs:build] 23:33:27 Build environment: GOARCH=amd64 GOOS=linux GOROOT=/usr/lib/golang GOBIN=/path/to/system-transparency/bin CGO_ENABLED=0
[initramfs:build] 23:33:27 WARNING: You are not using one of the recommended Go versions (have = go1.20.4, recommended = [go1.17]).
[initramfs:build]                       Some packages may not compile.
[initramfs:build]                       Go to https://golang.org/doc/install to find out how to install a newer version of Go,
[initramfs:build]                       or use https://godoc.org/golang.org/dl/go1.17 to install an additional version of Go.
[initramfs:build] 23:33:27 NOTE: building with the new gobusybox; to get the old behavior check out commit 8b790de
[initramfs:build] 23:33:33 Successfully built "out/artifacts/initramfs:incl-hostconfig.cpio.tmp" (size 7289992).
task: [initramfs:build] mv out/artifacts/initramfs:incl-hostconfig.cpio.tmp out/artifacts/initramfs:incl-hostconfig.cpio
task: [initramfs:generic] gzip -kf out/artifacts/initramfs:incl-hostconfig.cpio
task: [initramfs:generic] mv out/artifacts/initramfs:incl-hostconfig.cpio.gz out/artifacts/stboot.cpio.gz
task: [iso] bin/stmgr uki create -format iso -out 'out/stboot.iso' -kernel=out/artifacts/stboot.vmlinuz -initramfs=out/artifacts/stboot.cpio.gz
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
task: [demo:ospkg] bin/stmgr ospkg create -out 'out/ospkgs/os-pkg-example-ubuntu20.zip' -label='System Transparency Test OS' -kernel=cache/debos/ubuntu-focal-amd64.vmlinuz -initramfs=cache/debos/ubuntu-focal-amd64.cpio.gz -cmdline='console=tty0 console=ttyS0,115200n8 rw rdinit=/lib/systemd/systemd' -url=http://10.0.2.2:8080/os-pkg-example-ubuntu20.zip
task: [demo:ospkg] for i in {1..2}; do bin/stmgr ospkg sign -key=out/keys/example_keys/signing-key-$i.key -cert=out/keys/example_keys/signing-key-$i.cert -ospkg out/ospkgs/os-pkg-example-ubuntu20.zip; done
```

# Remote Attestation

To attest the demo VM, first build stauth and copy it to the VM and start it on
a second terminal.

The password for the default `stboot` user is `stboot`.

```bash
. setup.env
task demo:stauth
$ scp -P 2222 out/stauth stboot@localhost:/tmp
$ ssh -p 2222 stboot@localhost
stboot@ubuntu:~$ chmod +x /tmp/stauth
stboot@ubuntu:~$ echo stboot | sudo -S /tmp/stauth endorse --platform-server 0.0.0.0:3000
```

On another terminal use stauth to enroll the VM and endorse the stboot ISO and
OS package.
```bash
. setup.env
./out/stauth endorse --platform localhost:3000
# Plaform data written to ubuntu.platform.pb
./out/stauth endorse --stboot out/stboot.iso
# Stboot endorsement written to stboot.stboot.pb
./out/stauth endorse --ospkg-json out/ospkgs/os-pkg-example-ubuntu20.json \
    --ospkg-zip out/ospkgs/os-pkg-example-ubuntu20.zip
# OS package endorsement written to os-pkg-example-ubuntu20.ospkg.pb
```

Now we're ready to generate a quote and validate it. On the first terminal,
kill the `stauth endorse` process and start the quote service.
```bash
# Ctrl-C

stboot@ubuntu:~$ echo stboot | sudo -S /tmp/stauth quote host -l 0.0.0.0:3000
```

On the second terminal request the quote and supply the set of endorsements
generated above.
```bash
./out/stauth quote operator localhost:3000 ubuntu.platform.pb stboot.stboot.pb \
    os-pkg-example-ubuntu20.ospkg.pb
# Quote verified successfully
```

For a detailed explanation of stauth see [the stauth documentation](https://git.glasklar.is/system-transparency/core/stauth).
