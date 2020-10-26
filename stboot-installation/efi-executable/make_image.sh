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
    echo
    echo "[INFO]: backup existing image to $(realpath --relative-to="${root}" "${img_backup}")"
    mv "${img}" "${img_backup}"
fi

bash "${dir}/make_kernel.sh"

bash "${root}/stboot-installation/build_host_config.sh"

bash "${dir}/build_image.sh"