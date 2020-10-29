#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

acm_cache="${root}/cache/ACMs"

mkdir -p "${acm_cache}"

if [ -d "${acm_cache}" ]; then
    echo
    echo "[INFO]: Using cached ACMs in $(realpath --relative-to="${root}" "${acm_cache}")"
else
   echo ""
   echo "[INFO]: Grebbing all available ACMs from Intel"
   echo ""
   sinit-acm-grebber -of "${acm_cache}"

   echo "ACMs saved at: $(realpath --relative-to="${root}" "${acm_cache}")"
fi

ls -l "$(realpath --relative-to="${root}" "${acm_cache}")"

trap - EXIT