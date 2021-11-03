#!/usr/bin/env bash

set -Eeuo pipefail

default_name="host_configuration.json"
output=

while [ $# -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --output|-o)
      if test $# -gt 0; then
        j="$1"; shift 1
        output="$j"
      else
        >&2 echo "no output file specified"
        exit 1
      fi
      ;;
    *)
      break
      ;;
  esac
done

# append filename if not defined
if [[ -z "${output}" ]] || [[ "${output}" == */ ]];
then
  output="${output}${default_name}"
fi

mkdir -p "$(dirname "${output}")"

########################################

version=1
network_mode=${ST_NETWORK_MODE}
host_ip=${ST_HOST_IP}
host_gateway=${ST_HOST_GATEWAY}
host_dns=${ST_HOST_DNS}
host_network_interface=${ST_HOST_NETWORK_INTERFACE}
provisioning_url=("${ST_PROVISIONING_SERVER_URL[@]}")
url_array=$(printf '%s\n' "${provisioning_url[@]}" | jq -cR . | jq -cs .)

identity=$(openssl rand -hex 32)
authentication=$(openssl rand -hex 32)

cat >"${output}" <<EOL
{
   "version":${version},
   "network_mode":"${network_mode}",
   "host_ip":"${host_ip}",
   "gateway":"${host_gateway}",
   "dns":"${host_dns}",
   "network_interface":"${host_network_interface}",
   "provisioning_urls": ${url_array},
   "identity":"${identity}",
   "authentication":"${authentication}"
}
EOL
