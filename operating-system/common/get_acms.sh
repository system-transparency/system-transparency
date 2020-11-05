#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

cache="${root}/cache/ACMs"

if [ -d "${cache}" ]; then
    echo
    echo "[INFO]: Using cached ACMs in $(realpath --relative-to="${root}" "${cache}")"
else
    mkdir -p "${cache}"
    echo ""
    echo "[INFO]: Grebbing all available ACMs from Intel"
    echo ""
    sinit-acm-grebber -of "${cache}"

    echo "ACMs saved at: $(realpath --relative-to="${root}" "${cache}")"
fi

ls -l "$(realpath --relative-to="${root}" "${cache}")"

trap - EXIT