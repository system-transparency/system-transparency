#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# import global configuration
source "${DOTCONFIG:-.config}"

mem=${ST_QEMU_MEM}
image="${root}/out/stboot-installation/mbr-bootloader/stboot_mbr_installation.img"

tpm=$(mktemp -d --suffix='-tpm')

# Note: TPM1 needs to access tcsd as root..
swtpm_setup --tpmstate $tpm --tpm2 --config ${root}/cache/swtpm/etc/swtpm_setup.conf \
  --create-ek-cert --create-platform-cert --lock-nvram

echo "Starting $tpm"
swtpm socket --tpmstate dir=$tpm --tpm2 --ctrl type=unixio,path=/$tpm/swtpm-sock &


qemu-system-x86_64 \
  -enable-kvm \
  -drive if=virtio,file="${image}",format=raw \
  -nographic \
  -net user,hostfwd=tcp::2222-:2222 \
  -net nic \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-pci,rng=rng0 \
  -rtc base=localtime \
  -m "${mem}" \
  -chardev socket,id=chrtpm,path=/$tpm/swtpm-sock \
  -tpmdev emulator,id=tpm0,chardev=chrtpm \
  -device tpm-tis,tpmdev=tpm0

rm -r ${tpm:?}/*
