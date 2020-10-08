#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

tboot_cache="${root}/cache/tboot"
acm_cache="${root}/cache/ACMs"

tboot_src="http://hg.code.sf.net/p/tboot/code"
tboot_ver="v1.9.11"
tboot_out="${dir}/tboot.gz"
tboot_backup="${tboot_out}.backup"

mkdir -p "${tboot_cache}" "${acm_cache}"


if [ -f "${tboot_out}" ]; then
    while true; do
       echo "Current tboot:"
       ls -l "$(realpath --relative-to="${root}" "${tboot_out}")"
       read -rp "Rebuild tboot? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing file to $(realpath --relative-to="${root}" "$(dirname "${tboot_out}")")"; mv "${tboot_out}" "${tboot_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

if [ -f "${tboot_cache}/code/Makefile" ]; then
    echo "[INFO]: Using cached sources in $(realpath --relative-to="${root}" "${tboot_cache}/tboot")"
else
    echo "[INFO]: Cloning tboot sources from ${tboot_src}"
    cd "${tboot_cache}"
    hg clone "${tboot_src}"
    cd "${tboot_cache}/code"
    hg update "${tboot_ver}"
    cd "${dir}"
fi

echo ""
echo "[INFO]: Building tboot"
echo ""
cd "${tboot_cache}/code"
make dist
cd "${dir}"
cp "${tboot_cache}/code/dist/boot/tboot.gz" "${tboot_out}"

echo
echo "Tboot created at: $(realpath --relative-to="${root}" "${tboot_out}")"