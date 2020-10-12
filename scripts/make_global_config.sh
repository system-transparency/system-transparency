#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

config="${root}/run.config"
default="${root}/default.config"

if [ -f "${config}" ]; then
    while true; do
       read -rp "Override current run.config with default.config? (y/n)" yn
       case $yn in
          [Yy]* ) rm -f "${config}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

cp "${default}" "${config}"

echo
echo "[INFO]: run.config set to defaults"




