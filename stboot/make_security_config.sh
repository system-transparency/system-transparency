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
security_config="${dir}/include/${security_config_name}"
fingerprint_file=${ST_ROOTCERT_FINGERPRINT_FILE}
num_signatures=${ST_NUM_SIGNATURES}
bootmode=${ST_BOOTMETHOD}

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

echo "[INFO]: Create $(realpath --relative-to="${root}" "${security_config}")"

cat >"${security_config}" <<EOL
{
  "minimal_signatures_match": ${num_signatures},
  "fingerprints": [
    "$(cut -d' ' -f1 "${fingerprint_file}")"
  ],
  "build_timestamp": 0,
  "boot_mode": "${bootmode}"
}
EOL


