#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

echo "[INFO]: Make initramfs"
bash "${root}/stboot/make_initramfs.sh"

echo "[INFO]: Build kernel as an efistub"
bash ${dir}/build_efistub.sh $(id -nu)

echo "[INFO]: Create boot image and include efistub"
bash ${dir}/create_image.sh
