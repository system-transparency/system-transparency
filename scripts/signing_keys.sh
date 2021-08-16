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
        >&2 echo "no output directory specified"
        exit 1
      fi
      ;;
    *)
      break
      ;;
  esac
done

mkdir -p "${output}"

########################################

echo "Using 'stmanager keygen' to create a CA and a set of 5 signing keys, certified by it"

# Self-sign root certificate
stmanager keygen --isCA --certOut="${output}/root.cert" --keyOut="${output}/root.key"

# Signing keys
for I in {1..5}
do
    stmanager keygen --rootCert="${output}/root.cert" --rootKey="${output}/root.key" --certOut="${output}/signing-key-${I}.cert" --keyOut="${output}/signing-key-${I}.key"
done
