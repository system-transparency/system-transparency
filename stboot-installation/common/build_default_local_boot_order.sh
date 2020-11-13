#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

out="${root}/out/os-packages"
local_boot_order_file_name="local_boot_order"
local_boot_order_file="${out}/${local_boot_order_file_name}"

if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

find "${out}" -maxdepth 1 -type f -name "*.zip" -type f -printf "%f\n" | tac > "${local_boot_order_file}"
echo "[INFO]: Created $(realpath --relative-to="${root}" "${local_boot_order_file}")"
cat "${local_boot_order_file}"

trap - EXIT