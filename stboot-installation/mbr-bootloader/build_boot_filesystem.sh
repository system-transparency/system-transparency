#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

out="${root}/out/stboot-installation/mbr-bootloader"
name="boot_partition.vfat"
fs="${out}/${name}"
syslinux_cache="${root}/cache/syslinux/"
syslinux_dir="syslinux-6.03"
syslinux_config="${out}/syslinux.cfg"
linuxboot_kernel="${out}/linuxboot.vmlinuz"
host_config="${root}/out/stboot-installation/host_configuration.json"

echo
echo "[INFO]: Creating VFAT filesystems for STBOOT partition:"
size_vfat=$((12*(1<<20)))

echo "[INFO]: Using kernel: $(realpath --relative-to="${root}" "${linuxboot_kernel}")"

echo
# mkfs.vfat requires size as an (undefined) block-count; seem to be units of 1k
if [ -f "${fs}.tmp" ]; then rm "${fs}.tmp"; fi
mkfs.vfat -C -n "STBOOT" "${fs}.tmp" $((size_vfat >> 10))

echo "[INFO]: Installing Syslinux"
mmd -i "${fs}.tmp" ::syslinux

"${syslinux_cache}/${syslinux_dir}/bios/mtools/syslinux" --directory /syslinux/ --install "${fs}.tmp"

echo "[INFO]: Installing linuxboot kernel"
mcopy -i "${fs}.tmp" "${linuxboot_kernel}" ::

echo "[INFO]: Writing syslinux config"
mcopy -i "${fs}.tmp" "${syslinux_config}" ::syslinux/

echo "[INFO]: Writing host cofiguration"
mcopy -i "${fs}.tmp" "${host_config}" ::

echo "[INFO]: Done VFAT filesystems for STBOOT partition"
mv ${fs}{.tmp,}

trap - EXIT
