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
fingerprint_file=${ST_ROOTCERT_FINGERPRINT_FILE}
num_signatures=${ST_NUM_SIGNATURES}
bootmode=${ST_BOOTMETHOD}

echo
echo "[INFO]: Creating $(realpath --relative-to="${root}" "${security_config}")"

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


