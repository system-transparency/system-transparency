#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# import global configuration
source ${root}/run.config

security_config_name="security_configuration.json"
security_config="${dir}/files-initramfs/${security_config_name}"

if [ -f "${security_config}" ]; then
    while true; do
       echo "Current ${security_config_name}:"
       cat "${security_config}"
       read -rp "Override security_configuration.json settings from run.config? (y/n)" yn
       case $yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done
fi

bash "${dir}/build_security_config.sh"


