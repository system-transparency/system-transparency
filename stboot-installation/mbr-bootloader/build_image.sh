#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

img="${dir}/stboot_mbr_installation.img"
img_backup="${img}.backup"
syslinux_src="https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/"
syslinux_tar="syslinux-6.03.tar.xz"
syslinux_dir="syslinux-6.03"
syslinux_cache="${root}/cache/syslinux/"
syslinux_config="${dir}/syslinux.cfg"
lnxbt_kernel="${dir}/vmlinuz-linuxboot"
host_config="${root}/stboot-installation/files-stboot-partition/host_configuration.json"

if [ -f "${img}" ]; then
    echo
    echo "[INFO]: backup existing image to $(realpath --relative-to="${root}" "${img_backup}")"
    mv "${img}" "${img_backup}"
fi


if [ -d "${syslinux_cache}" ]; then
   echo "[INFO]: Using cached Syslinux in $(realpath --relative-to=${root} ${syslinux_cache})"
else
   echo "[INFO]: Downloading Syslinux Bootloader"
   wget "${syslinux_src}/${syslinux_tar}" -P "${syslinux_cache}"
   tar -xf "${syslinux_cache}/${syslinux_tar}" -C "${syslinux_cache}"
fi

echo "[INFO]: Using kernel: $(realpath --relative-to="${root}" "${lnxbt_kernel}")"

echo
echo "[INFO]: Creating VFAT filesystems for STBOOT partition:"
size_vfat=$((12*(1<<20)))
alignment=1048576

# mkfs.vfat requires size as an (undefined) block-count; seem to be units of 1k
if [ -f "${img}".vfat ]; then rm "${img}".vfat; fi
mkfs.vfat -C -n "STBOOT" "${img}".vfat $((size_vfat >> 10))

echo "[INFO]: Installing Syslinux"
mmd -i "${img}".vfat ::syslinux

"${syslinux_cache}/${syslinux_dir}/bios/mtools/syslinux" --directory /syslinux/ --install "${img}".vfat

echo "[INFO]: Copying syslinux config"
mcopy -i "${img}".vfat "${syslinux_config}" ::syslinux/

echo "[INFO]: Copying linuxboot kernel to image"
mcopy -i "${img}".vfat "${lnxbt_kernel}" ::

echo "[INFO]: Copying host cofiguration"
mcopy -i "${img}".vfat "${host_config}" ::

echo
echo "[INFO]: Creating EXT4 filesystems for STDATA partition:"
size_ext4=$((767*(1<<20)))

if [ -f "${img}".ext4 ]; then rm "${img}".ext4; fi
mkfs.ext4 -L "STDATA" "${img}".ext4 $((size_ext4 >> 10))

e2mkdir "${img}".ext4:/stboot
e2mkdir "${img}".ext4:/stboot/etc
e2mkdir "${img}".ext4:/stboot/os_pkgs
e2mkdir "${img}".ext4:/stboot/os_pkgs/new
e2mkdir "${img}".ext4:/stboot/os_pkgs/invalid
e2mkdir "${img}".ext4:/stboot/os_pkgs/known_good

echo "[INFO]: Copying OS packages to image (for LocalStorage bootmode)"
ls -l "${root}/os-packages/."
for i in "${root}/os-packages"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${img}".ext4:/stboot/os_pkgs/new
done

echo
echo "[INFO]: Constructing disk image from generated filesystems:"

offset_vfat=$(( alignment/512 ))
offset_ext4=$(( (alignment + size_vfat + alignment)/512 ))

# insert the filesystem to a new file at offset 1MB
dd if="${img}".vfat of="${img}" conv=notrunc obs=512 status=none seek=${offset_vfat}
dd if="${img}".ext4 of="${img}" conv=notrunc obs=512 status=none seek=${offset_ext4}

# extend the file by 1MB
truncate -s "+${alignment}" "${img}"

# Cleanup
rm "${img}".vfat
rm "${img}".ext4

echo "[INFO]: Adding partitions to disk image:"

# apply partitioning
parted -s --align optimal "${img}" mklabel gpt mkpart "STBOOT" fat32 "$((offset_vfat * 512))B" "$((offset_vfat * 512 + size_vfat))B" mkpart "STDATA" ext4 "$((offset_ext4 * 512))B" "$((offset_ext4 * 512 + size_ext4))B" set 1 boot on set 1 legacy_boot on

echo ""
echo "[INFO]: Installing MBR"
dd bs=440 count=1 conv=notrunc if="${syslinux_cache}/${syslinux_dir}/bios/mbr/gptmbr.bin" of="${img}" status=none

echo ""
echo "[INFO]: Image layout:"
parted -s "${img}" print

echo ""
echo "[INFO]: $(realpath --relative-to="${root}" "${img}") created."

trap - EXIT
