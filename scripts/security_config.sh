#!/usr/bin/env bash

set -Eeuo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

default_name="security_configuration.json"
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
num_signatures=${ST_NUM_SIGNATURES}
boot_mode=${ST_BOOT_MODE}
use_ospkg_cache=${ST_USE_PKG_CACHE}

cat >"${output}" <<EOL
{
  "version":${version},
  "min_valid_sigs_required": ${num_signatures},
  "boot_mode": "${boot_mode}",
  "use_ospkg_cache": ${use_ospkg_cache}
}
EOL
