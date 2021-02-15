#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

gopath="${root}/cache/go"
signing_key_dir="${root}/out/keys/signing_keys"

mkdir -p "${signing_key_dir}"


echo "[INFO]: using 'stmanager keygen' to create a CA and a set of 5 signing keys, certified by it"

# Self-sign root certificate
${gopath}/bin/stmanager keygen --isCA --certOut="${signing_key_dir}/root.cert" --keyOut="${signing_key_dir}/root.key"

# Signing keys
for I in 1 2 3
do
    ${gopath}/bin/stmanager keygen --rootCert="${signing_key_dir}/root.cert" --rootKey="${signing_key_dir}/root.key" --certOut="${signing_key_dir}/signing-key-${I}.cert" --keyOut="${signing_key_dir}/signing-key-${I}.key"
done

echo "[INFO]: Done. See 'stmanager keygen --help' for details on how to create keys manually."