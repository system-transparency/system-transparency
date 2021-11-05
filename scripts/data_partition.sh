#!/usr/bin/env bash

set -Eeuo pipefail

default_name="data_partition.ext4"
output=

while [ $# -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --output|-o)
      if test $# -gt 0; then
        j="$1"; shift 1
        output="$j"
      else
        >&2 echo "no output file specified"
        exit 1
      fi
      ;;
    *)
      break
      ;;
  esac
done

# append filename if not defined
if [[ -z "${output}" ]] || [[ "${output}" == */ ]];
then
  output="${output}${default_name}"
fi

mkdir -p "$(dirname "${output}")"

ospkg_dir="${ST_LOCAL_OSPKG_DIR}"
mkdir -p "${ospkg_dir}"

boot_mode="${ST_BOOT_MODE}"

########################################

boot_order_file="${ospkg_dir}/boot_order"

toBytes() {
 echo $1 | echo $((`sed 's/.*/\L\0/;s/t/Xg/;s/g/Xm/;s/m/Xk/;s/k/X/;s/b//;s/X/ *1024/g'`))
}

size_data_used=$(( $(du -b "${ospkg_dir}" | cut -f1) ))
size_data_extra=$(toBytes "${ST_DATA_PARTITION_EXTRA_SPACE:-0}")

size_data=$(( ${size_data_used} + ${size_data_extra} ))
inode_size=256
inode_ratio=16384
size_ext4=$(echo "scale=6;(${size_data}*(1.10+(${inode_size}/${inode_ratio})))+1" | bc -l | xargs printf "%0.f")

if [ -f "${output}.tmp" ]; then rm "${output}.tmp"; fi
mkfs.ext4 -I "${inode_size}" -i "${inode_ratio}" -L "STDATA" "${output}.tmp" $((${size_ext4} >> 10))

e2mkdir "${output}.tmp":/stboot
e2mkdir "${output}.tmp":/stboot/etc
e2mkdir "${output}.tmp":/stboot/os_pkgs
e2mkdir "${output}.tmp":/stboot/os_pkgs/local
e2mkdir "${output}.tmp":/stboot/os_pkgs/cache

timestamp_dir=$(mktemp -d)
trap "rm -r ${timestamp_dir}" EXIT
timestamp_file="${timestamp_dir}/system_time_fix"
date +%s > "${timestamp_file}"
e2cp "${timestamp_file}" "${output}.tmp":/stboot/etc
rm -r "${timestamp_dir}"
trap - EXIT

if [ "${boot_mode}" = "local" ];then
  ls -l "${ospkg_dir}"
  if [ -f "${boot_order_file}" ]; then e2cp "${boot_order_file}" "${output}.tmp":/stboot/os_pkgs/local; fi
  for i in "${ospkg_dir}"/*; do
    [ -e "$i" ] || continue
    e2cp "$i" "${output}.tmp":/stboot/os_pkgs/local
  done
fi

mv ${output}{.tmp,}
