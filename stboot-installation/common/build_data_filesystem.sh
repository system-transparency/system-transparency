#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

out="${root}/out/stboot-installation"
name="data_partition.ext4"
fs="${out}/${name}"
local_boot_order_file_name="local_boot_order"
local_boot_order_file="${root}/out/os-packages/${local_boot_order_file_name}"

echo
echo "[INFO]: Creating EXT4 filesystems for STDATA partition:"
size_ext4=$((767*(1<<20)))

if [ -f "${fs}" ]; then rm "${fs}"; fi
mkfs.ext4 -L "STDATA" "${fs}" $((size_ext4 >> 10))

e2mkdir "${fs}":/stboot
e2mkdir "${fs}":/stboot/etc
e2mkdir "${fs}":/stboot/os_pkgs
e2mkdir "${fs}":/stboot/os_pkgs/local
e2mkdir "${fs}":/stboot/os_pkgs/cache

echo
echo "[INFO]: Writing UNIX timestamp"
timestamp_file="${out}/system_time_fix"
date +%s > "${timestamp_file}"
cat "${timestamp_file}"
e2cp "${timestamp_file}" "${fs}":/stboot/etc
rm "${timestamp_file}"

echo
echo "[INFO]: Copying OS packages to image (for local boot method)"
ls -l "${root}/out/os-packages/."
e2cp "${local_boot_order_file}" "${fs}":/stboot/etc
for i in "${root}/out/os-packages"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${fs}":/stboot/os_pkgs/local
done

trap - EXIT