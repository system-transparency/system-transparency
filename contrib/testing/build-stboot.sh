#! /bin/sh

set -eu
set -x

([ -f out/stboot.iso ] && rm out/stboot.iso) || true
task linux:kernel-prebuilt iso 

stmgr uki create -format iso -force \
  -out 'out/stboot.iso' \
  -kernel=out/artifacts/stboot.vmlinuz \
  -initramfs=out/artifacts/stboot.cpio.gz \
  -cmdline=''
