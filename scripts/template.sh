#!/usr/bin/env bash

set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"
default_name="template.txt"

output=""

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

echo "${output}"
echo "template file" > "${output}"
