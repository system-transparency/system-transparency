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
name="host_configuration.json"
host_config="${out}/${name}"

version=1
network_mode=${ST_NETWORK_MODE}
host_ip=${ST_HOST_IP}
host_gateway=${ST_HOST_GATEWAY}
host_dns=${ST_HOST_DNS}
provisioning_url=("${ST_PROVISIONING_SERVER_URL[@]}")
url_array=$(printf '%s\n' "${provisioning_url[@]}" | jq -cR . | jq -cs .)

identity=$(hexdump -n 32 -e '8/4 "%08X"' /dev/urandom)
authentication=$(hexdump -n 32 -e '8/4 "%08X"' /dev/urandom)
entropy_seed=$(hexdump -n 32 -e '8/4 "%08X"' /dev/urandom)


if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

echo
echo "[INFO]: Creating $(realpath --relative-to="${root}" "${host_config}")"

cat >"${host_config}" <<EOL
{
   "version":${version},
   "network_mode":"${network_mode}",
   "host_ip":"${host_ip}",
   "gateway":"${host_gateway}",
   "dns":"${host_dns}",
   "provisioning_urls": ${url_array},
   "identity":"${identity}",
   "authentication":"${authentication}",
   "entropy_seed":"${entropy_seed}"
}
EOL

cat "$(realpath --relative-to="${root}" "${host_config}")"