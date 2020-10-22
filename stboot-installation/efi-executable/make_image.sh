#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

img="${dir}/stboot_efi_installation.img"
img_backup="${img}.backup"
efistub="${dir}/stboot.efi"

if [ -f "${img}" ]; then
    while true; do
        echo "Current image file:"
        ls -l "$(realpath --relative-to="${root}" "${img}")"
        read -rp "Rebuild image? (y/n)" yn
        case $yn in
            [Yy]* ) echo "[INFO]: backup existing image to $(realpath --relative-to="${root}" "${img_backup}")"; mv "${img}" "${img_backup}"; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
   done
fi

echo "[INFO]: check for LinuxBoot initramfs including stboot bootloader"
bash "${root}/stboot-installation/make_initramfs.sh"

echo "[INFO]: check for LinuxBoot kernel as an efistub"
bash "${dir}/make_efistub.sh"

echo "[INFO]: using efistub: $(realpath --relative-to="${root}" "${efistub}")"

echo "[INFO]: Creating VFAT filesystems for STBOOT partition:"
size_vfat=$((12*(1<<20)))
alignment=1048576

# mkfs.vfat requires size as an (undefined) block-count; seem to be units of 1k
if [ -f "${img}".vfat ]; then rm "${img}".vfat; fi
mkfs.vfat -C -n "STBOOT" "${img}".vfat $((size_vfat >> 10))

echo "[INFO]: Installing STBOOT.EFI"
mmd -i "${img}".vfat ::EFI
mmd -i "${img}".vfat ::EFI/BOOT

mcopy -i "${img}".vfat "${efistub}" ::/EFI/BOOT/BOOTX64.EFI

echo "[INFO]: Creating EXT4 filesystems for STDATA partition:"
size_ext4=$((767*(1<<20)))

if [ -f "${img}".ext4 ]; then rm "${img}".ext4; fi
mkfs.ext4 -L "STDATA" "${img}".ext4 $((size_ext4 >> 10))

echo "[INFO]: Copying data files to image"
ls -l "${root}/stboot-installation/data/."

e2mkdir "${img}".ext4:/etc
e2mkdir "${img}".ext4:/stboot
e2mkdir "${img}".ext4:/stboot/etc
e2mkdir "${img}".ext4:/stboot/os_pkgs
e2mkdir "${img}".ext4:/stboot/os_pkgs/new
e2mkdir "${img}".ext4:/stboot/os_pkgs/invalid
e2mkdir "${img}".ext4:/stboot/os_pkgs/known_good

for i in "${root}/stboot-installation/data"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${img}".ext4:/stboot/etc
done

e2ls "${img}".ext4:/stboot/etc/

echo "[INFO]: Copying OS packages to image (for LocalStorage bootmode)"
ls -l "${root}/os-packages/."
for i in "${root}/os-packages"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${img}".ext4:/stboot/os_pkgs/new
done

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
echo "[INFO]: Image layout:"
parted -s "${img}" print

echo ""
echo "[INFO]: $(realpath --relative-to="${root}" "${img}") created."
