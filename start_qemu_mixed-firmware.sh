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

image="${root}/deploy/mixed-firmware/Syslinux_Linuxboot.img"

qemu-system-x86_64 -drive if=virtio,file=${image},format=raw \
-object rng-random,filename=/dev/urandom,id=rng0 \
-device e1000,netdev=n1 \
-netdev user,id=n1,hostfwd=tcp:127.0.0.1:23-:2222,net=192.168.1.0/24,host=192.168.1.1 \
-rtc base=localtime \
-m 8192M \
-device virtio-rng-pci,rng=rng0 \
-serial stdio  \
#-monitor /dev/null  \
#-nographic \
#-append earlyprintk=ttyS0,115200\ console=ttyS0 \

