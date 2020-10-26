#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config

config=${dir}/syslinux.cfg

if [ -f "${config}" ]; then
    while true; do
       echo "Current Syslinux config:"
       cat "$(realpath --relative-to="${root}" "${config}")"
       read -rp "Override Syslinux config settings from run.config? (y/n)" yn
       case $yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

bash "${dir}/build_syslinux_config.sh"