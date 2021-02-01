#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

MAKE=${MAKE:-make}

out="${root}/out/tboot"
name="tboot.gz"
tboot="${out}/${name}"
tboot_backup="${tboot}.backup"
version="v1.9.11"
src_url="http://hg.code.sf.net/p/tboot/code"
cache="${root}/cache/tboot"

if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

if [ -f "${tboot}" ]; then
    echo "[INFO]: backup existing file to $(realpath --relative-to="${root}" "$(dirname "${tboot}")")"
    mv "${tboot}" "${tboot_backup}"
fi

if [ -d "${cache}/code" ]; then
    echo "[INFO]: Using cached sources in $(realpath --relative-to="${root}" "${cache}")"
else
    mkdir -p "${cache}"
    echo "[INFO]: Cloning tboot sources from ${src_url}"
    cd "${cache}"
    hg clone "${src_url}"
    cd "${cache}/code"
    hg update "${version}"
    cd "${dir}"
fi

echo ""
echo "[INFO]: Building tboot"
echo ""
cd "${cache}/code"
currentver="$(gcc -dumpversion | cut -d . -f 1)"
if [ "$currentver" -ge "9" ]; then
    export CFLAGS="-Wno-error=address-of-packed-member"
    export TBOOT_CFLAGS="$CFLAGS"
fi
${MAKE} dist --no-print-directory
cd "${dir}"
cp "${cache}/code/dist/boot/tboot.gz" "${tboot}"

echo
echo "Tboot created at: $(realpath --relative-to="${root}" "${tboot}")"

trap - EXIT
