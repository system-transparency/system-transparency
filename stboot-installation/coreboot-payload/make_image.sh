#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

img="${dir}/stboot_coreboot_installation.img"
img_backup="${img}.backup"

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

echo "[INFO]: Creating EXT4 filesystems for STDATA partition:"
size_ext4=$((767*(1<<20)))
alignment=1048576

if [ -f "${img}".ext4 ]; then rm "${img}".ext4; fi
mkfs.ext4 -L "STDATA" "${img}".ext4 $((size_ext4 >> 10))

echo "[INFO]: Copying data files to image"
ls -l "${root}/stboot-installation/data/."

e2mkdir "${img}".ext4:/etc
e2mkdir "${img}".ext4:/stboot
e2mkdir "${img}".ext4:/stboot/etc
e2mkdir "${img}".ext4:/stboot/os-pkgs
e2mkdir "${img}".ext4:/stboot/os-pkgs/new
e2mkdir "${img}".ext4:/stboot/os-pkgs/invalid
e2mkdir "${img}".ext4:/stboot/os-pkgs/known_good

for i in "${root}/stboot-installation/data"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${img}".ext4:/stboot/etc
done

e2ls "${img}".ext4:/stboot/etc/

echo "[INFO]: Copying OS packages to image (for LocalStorage bootmode)"
ls -l "${root}/os-packages/."
for i in "${root}/os-packages"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${img}".ext4:/stboot/os-pkgs/new
done

echo "[INFO]: Constructing disk image from generated filesystems:"

offset_ext4=$(( alignment/512 ))

# insert the filesystem to a new file at offset 1MB
dd if="${img}".ext4 of="${img}" conv=notrunc obs=512 status=none seek=${offset_ext4}

# extend the file by 1MB
truncate -s "+${alignment}" "${img}"

# Cleanup
rm "${img}".ext4

echo "[INFO]: Adding partition to disk image:"

# apply partitioning
parted -s --align optimal "${img}" mklabel gpt mkpart "STDATA" ext4 "$((offset_ext4 * 512))B" "$((offset_ext4 * 512 + size_ext4))B"

echo ""
echo "[INFO]: Image layout:"
parted -s "${img}" print

echo ""
echo "[INFO]: $(realpath --relative-to="${root}" "${img}") created."

echo ""
echo "[INFO]: Creation of coreboot-rom not automated yet."
echo "[INFO]: Plese follow the steps in stboot-installation/coreboot-payload/README.md"