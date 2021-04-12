#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source "${DOTCONFIG:-.config}"

out="${root}/out/stboot-installation"
name="data_partition.ext4"
fs="${out}/${name}"
local_boot_order_file_name="boot_order"
local_boot_order_file="${root}/out/os-packages/${local_boot_order_file_name}"
os_pkg_dir="${root}/out/os-packages"
size_ext4="${ST_DATA_PARTITION_SZIZE}"

if [ ! -d "${os_pkg_dir}" ]; then mkdir -p "${os_pkg_dir}"; fi

# if empty set to size of os_pkg_dir + 100MB
if [ -z "${size_ext4}" ]; then size_ext4=$(( $(du -b "${os_pkg_dir}" | cut -f1) +(100*(1<<20)) )); fi

echo
echo "[INFO]: Creating EXT4 filesystems for STDATA partition:"

if [ -f "${fs}.tmp" ]; then rm "${fs}.tmp"; fi
mkfs.ext4 -L "STDATA" "${fs}.tmp" $((size_ext4 >> 10))

e2mkdir "${fs}.tmp":/stboot
e2mkdir "${fs}.tmp":/stboot/etc
e2mkdir "${fs}.tmp":/stboot/os_pkgs
e2mkdir "${fs}.tmp":/stboot/os_pkgs/local
e2mkdir "${fs}.tmp":/stboot/os_pkgs/cache

echo
echo "[INFO]: Writing UNIX timestamp"
timestamp_file="${out}/system_time_fix"
date +%s > "${timestamp_file}"
cat "${timestamp_file}"
e2cp "${timestamp_file}" "${fs}.tmp":/stboot/etc
rm "${timestamp_file}"

echo
echo "[INFO]: Copying OS packages to image (for local boot method)"
ls -l "${root}/out/os-packages/."
e2cp "${local_boot_order_file}" "${fs}.tmp":/stboot/os_pkgs/local
for i in "${os_pkg_dir}"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${fs}.tmp":/stboot/os_pkgs/local
done

mv ${fs}{.tmp,}

trap - EXIT
