#!/bin/sh

BASE=$(dirname "$0")

KERNELNAME=${1:-debian-buster-amd64.vmlinuz}
INITRDNAME=${2:-debian-buster-amd64.cpio.gz}
CONFIGPATH=${3:-$BASE/../configs/debian}

#Copy kernel and initramfs to example directory
cp $BASE/out/debian-buster-amd64.vmlinuz $CONFIGPATH/kernels/
cp $BASE/out/debian-buster-amd64.cpio.gz $CONFIGPATH/initrds/

touch $CONFIGPATH/manifest.json
sudo echo '{ 
  "version": 1, 
  "configs": [ 
    { 
      "name": "debian reproducible", 
      "kernel": "kernels/'$KERNELNAME'", 
      "kernel_args": "console=tty0 console=ttyS0,115200n8 rw rdinit=/lib/systemd/systemd", 
      "initramfs": "initrds/'$INITRDNAME'" 
    } 
  ], 
  "rootCert": "signing/root.cert" 
}' > $CONFIGPATH/manifest.json