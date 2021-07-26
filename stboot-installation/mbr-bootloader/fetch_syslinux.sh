#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

syslinux_src="https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/"
syslinux_tar="syslinux-6.03.tar.xz"
syslinux_cache="${root}/cache/syslinux/"

[ -d "${syslinux_cache}" ] && rm -r "${syslinux_cache}"

mkdir -p "${syslinux_cache}"
echo
echo "[INFO]: Downloading Syslinux Bootloader"
wget -q "${syslinux_src}/${syslinux_tar}" -P "${syslinux_cache}"
tar -xf "${syslinux_cache}/${syslinux_tar}" -C "${syslinux_cache}"

trap - EXIT
