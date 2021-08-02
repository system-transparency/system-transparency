#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

out="${root}/out/stboot-installation"
name="security_configuration.json"
security_config="${out}/${name}"

version=1
num_signatures=${ST_NUM_SIGNATURES}
boot_mode=${ST_BOOT_MODE}
use_ospkg_cache=${ST_USE_PKG_CACHE}

if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

echo
echo "[INFO]: Creating $(realpath --relative-to="${root}" "${security_config}")"

cat >"${security_config}" <<EOL
{
  "version":${version},
  "minimal_signatures_match": ${num_signatures},
  "boot_mode": "${boot_mode}",
  "use_ospkg_cache": ${use_ospkg_cache}
}
EOL

cat "$(realpath --relative-to="${root}" "${security_config}")"
