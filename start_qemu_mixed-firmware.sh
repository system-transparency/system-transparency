#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="${dir}/$(basename "${BASH_SOURCE[0]}")"
base="$(basename ${file} .sh)"
root="$dir"

image="${root}/deploy/mixed-firmware/MBR_Syslinux_Linuxboot.img"

qemu-system-x86_64 -drive if=virtio,file=${image},format=raw -device virtio-rng-pci -m 8192 -nographic 
