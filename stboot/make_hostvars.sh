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

hostvars_name="hostvars.json"
hostvars="${dir}/include/${hostvars_name}"
fingerprint_file=${ST_ROOTCERT_FINGERPRINT_FILE}
num_signatures=${ST_HOSTVARS_NUM_SIGNATURES}
bootmode=${ST_HOSTVARS_BOOTMODE}

if [ -f "${hostvars}" ]; then
    while true; do
       echo "Current ${hostvars_name}:"
       cat "${hostvars}"
       read -rp "Reset hostvars.json? (y/n)" yn
       case $yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done
fi

echo "[INFO]: Create $(realpath --relative-to="${root}" "${hostvars}")"

cat >"${hostvars}" <<EOL
{
  "minimal_signatures_match": ${num_signatures},
  "fingerprints": [
    "$(cut -d' ' -f1 "${fingerprint_file}")"
  ],
  "build_timestamp": 0,
  "boot_mode": "${bootmode}"
}
EOL


