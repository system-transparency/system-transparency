#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config

out="${root}/out/stboot-installation"
name="security_configuration.json"
security_config="${out}/${name}"
fingerprint_file=${ST_ROOTCERT_FINGERPRINT_FILE}
num_signatures=${ST_NUM_SIGNATURES}
bootmode=${ST_BOOTMETHOD}

if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

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

cat "$(realpath --relative-to="${root}" "${security_config}")"

