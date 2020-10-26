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

host_ip=${ST_HOST_IP}
host_gateway=${ST_HOST_GATEWAY}
host_dns=${ST_HOST_DNS}
provisioning_url=${ST_PROVISIONING_SERVER_URL}


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

echo "[INFO]: Create $(realpath --relative-to="${root}" "${host_config}")"

cat >"${host_config}" <<EOL
{
   "host_ip":"${host_ip}",
   "gateway":"${host_gateway}",
   "dns":"${host_dns}",
   "provisioning_urls": ["${provisioning_url}"],
   "ntp_urls": ["0.beevik-ntp.pool.ntp.org"]
}
EOL


