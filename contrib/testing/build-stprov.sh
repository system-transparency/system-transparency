#! /bin/sh

set -eu
set -x

# => out/artifacts/stprov.cpio.gz
task linux:kernel-prebuilt demo:initramfs-stprov demo:ospkg-stprov

# => out/ospkgs/stprov.zip
stmgr ospkg create -out 'out/ospkgs/stprov.zip' -label='Provisioning Tool' -kernel=out/artifacts/stboot.vmlinuz -initramfs=out/artifacts/stprov.cpio.gz -cmdline=''

# => out/ospkgs/stprov.json
for i in {1..2}; do cache/go/bin/stmgr ospkg sign -key=out/keys/example_keys/signing-key-$i.key -cert=out/keys/example_keys/signing-key-$i.cert -ospkg out/ospkgs/stprov.zip; done

# => out/artifacts/stboot.cpio.gz
task iso-provision

# => out/stprov.iso
stmgr uki create -format iso -out out/stprov.iso -kernel contrib/linuxboot.vmlinuz -initramfs out/artifacts/stprov.cpio.gz -cmdline=''
