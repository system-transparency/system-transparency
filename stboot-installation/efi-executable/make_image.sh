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

echo "[INFO]: check for Host configuration"
bash "${root}/stboot-installation/make_host_config.sh"

bash "${dir}/build_image.sh"