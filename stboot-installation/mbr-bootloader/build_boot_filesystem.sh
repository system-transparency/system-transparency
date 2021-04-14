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
syslinux_cache="${root}/cache/syslinux"
syslinux_dir="${syslinux_cache}/syslinux-6.03"
syslinux_config="${out}/syslinux.cfg"
linuxboot_kernel="${out}/linuxboot.vmlinuz"
host_config="${root}/out/stboot-installation/host_configuration.json"
syslinux_efi32="${out}/BOOTIA32.EFI"
syslinux_efi64="${out}/BOOTX64.EFI"
syslinux_e32="${syslinux_dir}/efi32/com32/elflink/ldlinux/ldlinux.e32"
syslinux_e64="${syslinux_dir}/efi64/com32/elflink/ldlinux/ldlinux.e64"

echo
echo "[INFO]: Creating VFAT filesystems for STBOOT partition:"
size_vfat=$((12*(1<<20)))

echo "[INFO]: Using kernel: $(realpath --relative-to="${root}" "${linuxboot_kernel}")"

echo
# mkfs.vfat requires size as an (undefined) block-count; seem to be units of 1k
if [ -f "${fs}.tmp" ]; then rm "${fs}.tmp"; fi
mkfs.vfat -C -n "STBOOT" "${fs}.tmp" $((size_vfat >> 10))

echo "[INFO]: Installing Syslinux"
mmd -i "${fs}.tmp" ::boot
mmd -i "${fs}.tmp" ::boot/syslinux

"${syslinux_dir}/bios/mtools/syslinux" --directory /boot/syslinux/ --install "${fs}.tmp"

echo "[INFO]: Installing linuxboot kernel"
mcopy -i "${fs}.tmp" "${linuxboot_kernel}" ::

echo "[INFO]: Writing syslinux config"
mcopy -i "${fs}.tmp" "${syslinux_config}" ::boot/syslinux/

echo "[INFO]: Writing host cofiguration"
mcopy -i "${fs}.tmp" "${host_config}" ::

echo "[INFO]: Done VFAT filesystems for STBOOT partition"
mv ${fs}{.tmp,}

echo "[INFO]: Installing EFI"
mmd -i "${fs}" ::EFI
mmd -i "${fs}" ::EFI/BOOT
mcopy -i "${fs}" "${syslinux_e32}" ::boot/syslinux/
mcopy -i "${fs}" "${syslinux_e64}" ::boot/syslinux/

echo "[INFO]: Installing efi32"
mcopy -i "${fs}" "${syslinux_efi32}" ::/EFI/BOOT/

echo "[INFO]: Installing efi64"
mcopy -i "${fs}" "${syslinux_efi64}" ::/EFI/BOOT/

trap - EXIT
