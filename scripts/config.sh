#!/usr/bin/env bash

set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

default_name="config"
default_config="${root}/contrib/default.config"

output=

while test $# -gt 0; do
  case "$1" in
    -o)
      shift
      if test $# -gt 0; then
        output="$1"
      else
        echo "no output dir specified"
        exit 1
      fi
      shift
      ;;
    --output*)
      output=$(echo "$1" | sed -e 's/^[^=]*=//g')
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z "${output}" ]] || [[ "${output}" == */ ]];
then
  output="${output}${default_name}"
fi

mkdir -p "$(dirname "${output}")"

########################################

if [[ -f "${output}" ]];
then
  if diff "${output}" "${default_config}" >/dev/null
  then
    echo "Configuration already up-to-date"
    exit 0
  else
    echo "Moving old config to ${output}.old"
    mv "${output}" "${output}.old"
  fi
fi

cp "${default_config}" "${output}"
