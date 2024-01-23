#! /bin/bash

set -eu
set -x

task demo:ospkg

./bin/stmgr ospkg create \
  -out 'out/ospkgs/os-pkg-example-ubuntu20.zip' \
  -label='System Transparency Test OS' \
  -kernel=cache/debos/ubuntu-focal-amd64.vmlinuz \
  -initramfs=cache/debos/ubuntu-focal-amd64.cpio.gz \
  -cmdline='rw rdinit=/lib/systemd/systemd' \
  -url=http://192.168.67.2/os-pkg-example-ubuntu20.zip

for i in {1..2}
do
  ./bin/stmgr ospkg sign \
    -key="out/keys/example_keys/signing-key-$i.key" \
    -cert="out/keys/example_keys/signing-key-$i.cert" \
    -ospkg out/ospkgs/os-pkg-example-ubuntu20.zip
done
