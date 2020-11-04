#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

out="${root}/out/stboot-installation/efi-application"
name="boot_partition.vfat"
fs="${out}/${name}"
linuxboot_kernel="${out}/linuxboot.efi"
host_config="${root}/out/stboot-installation/host_configuration.json"

echo
echo "[INFO]: Creating VFAT filesystems for STBOOT partition:"
size_vfat=$((12*(1<<20)))

echo "[INFO]: Using kernel (efi stub): $(realpath --relative-to="${root}" "${linuxboot_kernel}")"

# mkfs.vfat requires size as an (undefined) block-count; seem to be units of 1k
if [ -f "${fs}" ]; then rm "${fs}"; fi
mkfs.vfat -C -n "STBOOT" "${fs}" $((size_vfat >> 10))

echo "[INFO]: Installing STBOOT.EFI"
mmd -i "${fs}" ::EFI
mmd -i "${fs}" ::EFI/BOOT

mcopy -i "${fs}" "${linuxboot_kernel}" ::/EFI/BOOT/BOOTX64.EFI

echo "[INFO]: Writing host cofiguration"
mcopy -i "${fs}" "${host_config}" ::

trap - EXIT