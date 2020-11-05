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

echo
echo "[INFO]: Creating EXT4 filesystems for STDATA partition:"
size_ext4=$((767*(1<<20)))

if [ -f "${fs}" ]; then rm "${fs}"; fi
mkfs.ext4 -L "STDATA" "${fs}" $((size_ext4 >> 10))

e2mkdir "${fs}":/stboot
e2mkdir "${fs}":/stboot/etc
e2mkdir "${fs}":/stboot/os_pkgs
e2mkdir "${fs}":/stboot/os_pkgs/new
e2mkdir "${fs}":/stboot/os_pkgs/invalid
e2mkdir "${fs}":/stboot/os_pkgs/known_good

echo "[INFO]: Copying OS packages to image (for local boot method)"
ls -l "${root}/out/os-packages/."
for i in "${root}/out/os-packages"/*; do
  [ -e "$i" ] || continue
  e2cp "$i" "${fs}":/stboot/os_pkgs/new
done

trap - EXIT