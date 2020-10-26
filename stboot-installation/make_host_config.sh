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

host_config_name="host_configuration.json"
host_config="${dir}/files-stboot-partition/${host_config_name}"

if [ -f "${host_config}" ]; then
    while true; do
       echo "Current ${host_config_name}:"
       cat "${host_config}"
       read -rp "Override host_configuration.json settings from run.config? (y/n)" yn
       case $yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done
fi

bash "${dir}/build_host_config.sh"


