#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

acm_cache="${root}/cache/ACMs"
acm_backup="${root}/cache/ACM-backups"

mkdir -p "${acm_cache}"
mkdir -p "${acm_backup}"

if [ "$(find "${acm_cache}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    #"Not empty, do something"
    while true; do
       echo "Current Authenticated Code Modules:"
       ls -l "$(realpath --relative-to="${root}" "${acm_cache}")"
       read -rp "Update ACMs? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing files to $(realpath --relative-to="${root}" "$(dirname "${acm_backup}")")"; mv "${acm_cache}/"* "${acm_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

echo ""
echo "[INFO]: Grebbing all available ACMs from Intel"
echo ""
sinit-acm-grebber -of "${acm_cache}"

ls -l "$(realpath --relative-to="${root}" "${acm_cache}")"
echo "ACMs saved at: $(realpath --relative-to="${root}" "${acm_cache}")"
