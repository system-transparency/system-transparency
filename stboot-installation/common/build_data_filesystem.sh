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

toBytes() {
 echo $1 | echo $((`sed 's/.*/\L\0/;s/t/Xg/;s/g/Xm/;s/m/Xk/;s/k/X/;s/b//;s/X/ *1024/g'`))
}

out="${root}/out/stboot-installation"
name="data_partition.ext4"
fs="${out}/${name}"
local_boot_order_file_name="boot_order"
local_boot_order_file="${root}/out/os-packages/${local_boot_order_file_name}"
os_pkg_dir="${root}/out/os-packages"

if [ ! -d "${os_pkg_dir}" ]; then mkdir -p "${os_pkg_dir}"; fi

size_data_used=$(( $(du -b "${os_pkg_dir}" | cut -f1) ))
size_data_extra=$(toBytes "${ST_DATA_PARTITION_EXTRA_SPACE:-0}")

#size_data=$(( 20000000 + ${size_data_used} + ${size_data_extra} ))
size_data=$(( ${size_data_used} + ${size_data_extra} ))
inode_size=256
inode_ratio=16384
size_ext4=$(echo "scale=6;(${size_data}*(1.10+(${inode_size}/${inode_ratio})))+1" | bc -l | xargs printf "%0.f")

mkdir -p "${out}"

echo
echo "[INFO]: Creating EXT4 filesystems for STDATA partition:"

if [ -f "${fs}.tmp" ]; then rm "${fs}.tmp"; fi
mkfs.ext4 -I "${inode_size}" -i "${inode_ratio}" -L "STDATA" "${fs}.tmp" $((${size_ext4} >> 10))

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
if [ -f "${local_boot_order_file}" ]; then e2cp "${local_boot_order_file}" "${fs}.tmp":/stboot/os_pkgs/local; fi
for i in "${os_pkg_dir}"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${fs}.tmp":/stboot/os_pkgs/local
done

mv ${fs}{.tmp,}

trap - EXIT
