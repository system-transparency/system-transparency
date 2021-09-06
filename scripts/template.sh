#!/usr/bin/env bash

set -Eeuo pipefail

default_name="template.txt"
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

# append filename if output is a directory
if [[ -z "${output}" ]] || [[ "${output}" == */ ]];
then
  output="${output}${default_name}"
fi

mkdir -p "$(dirname "${output}")"

########################################

echo "${output}"
echo "template file" > "${output}"
