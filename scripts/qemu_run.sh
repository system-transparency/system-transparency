#!/usr/bin/env bash

set -Eeuo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

image=
boot=mbr
ovmf=
ovmf_locs=("/usr/share/OVMF/OVMF_CODE.fd" "/usr/share/edk2/ovmf/OVMF_CODE.fd")
declare -a qemu_args

function locate_ovmf {
  for i in "${ovmf_locs[@]}"
  do
    if [ -f "$i" ]; then
      ovmf="$i"
      return 0
    fi
  done
  if [ "$ovmf" == "" ]; then
    >&2 echo "ERROR: OVMF not found"
    return 1
  fi
}

while [ $# -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --image|-i)
      if test $# -gt 0; then
        j="$1"; shift 1
        image="$j"
      else
        >&2 echo "no image file specified"
        >&2 echo "(--image <image>)"
        exit 1
      fi
      ;;
    --bootloader|-b)
      if test $# -gt 0; then
        j="$1"; shift 1
        boot="$j"
      else
        >&2 echo "no boot mode specified"
        >&2 echo "(--bootloader <mbr/efi>)"
        exit 1
      fi
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z "${image}" ]];
then
  >&2 echo "usage: $0 --image <stboot-image>"
  exit 1
fi

case "$boot" in
  mbr)
    ;;
  efi)
    locate_ovmf
    qemu_args+=("-bios")
    qemu_args+=("${ovmf}")
    ;;
  *)
    >&2 echo "unknown boot mode: $boot"
    exit 1
esac


########################################

mem=4G

tpm=$(mktemp -d --suffix='-tpm')

swtpm_setup --tpmstate $tpm --tpm2 --config ${root}/cache/swtpm/etc/swtpm_setup.conf \
  --create-ek-cert --create-platform-cert --lock-nvram

echo "Starting $tpm"
swtpm socket --tpmstate dir=$tpm --tpm2 --ctrl type=unixio,path=/$tpm/swtpm-sock &

# use kvm if avaiable
if [[ -w /dev/kvm ]]; then
qemu_args+=("-enable-kvm")
fi

qemu-system-x86_64 \
  -M q35 \
  -drive if=virtio,file="${image}",format=raw \
  -net user,hostfwd=tcp::2222-:2222 \
  -net nic \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-pci,rng=rng0 \
  -rtc base=localtime \
  -m "${mem}" \
  -chardev socket,id=chrtpm,path=/$tpm/swtpm-sock \
  -tpmdev emulator,id=tpm0,chardev=chrtpm \
  -device tpm-tis,tpmdev=tpm0 \
  -nographic \
  "${qemu_args[@]}"

rm -r ${tpm:?}/*
