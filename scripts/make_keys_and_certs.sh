#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

signing_key_dir="${root}/out/keys/signing_keys"
cpu_key_dir="${root}/out/keys/cpu_keys"

mkdir -p "${signing_key_dir}"
mkdir -p "${cpu_key_dir}"

OPENSSL=openssl

echo "[INFO]: create a CA and a set of 5 signing keys, certified by it"

# Root key
"${OPENSSL}" genrsa -f4 -out "${signing_key_dir}/root.key" 4096

# Self-sign root certificate
"${OPENSSL}" req -new -key "${signing_key_dir}/root.key" -batch -subj '/CN=Test Root CA' -out "${signing_key_dir}/root.cert" -x509 -days 1024

for I in 1 2 3 4 5
do
  # Gen signing key
  "${OPENSSL}" genrsa -f4 -out "${signing_key_dir}/signing-key-${I}.key" 4096
  # Certification request
  "${OPENSSL}" req -new -key "${signing_key_dir}/signing-key-${I}.key" -batch  -subj '/CN=Signing Key '"${I}" -out "${signing_key_dir}/signing-key-${I}.req"
  # Fullfil certification req
  "${OPENSSL}" x509 -req -in "${signing_key_dir}/signing-key-${I}.req" -CA "${signing_key_dir}/root.cert" -CAkey "${signing_key_dir}/root.key" -out "${signing_key_dir}/signing-key-${I}.cert" -days 365 -CAcreateserial
  # Remove certification req
  rm "${signing_key_dir}/signing-key-${I}.req"
done

echo "[INFO]: root.cert:            The root CA certificate"
echo "[INFO]: root.key:             The root CA private key"
echo "[INFO]: rootcert.fingerprint: The root CA certificate's fingerprint"
echo "[INFO]: signing-key-N.cert:   The certificate corresponding to key N"
echo "[INFO]: signing-key-N.key:    Key N's private key"

# SSH key generation for cpu
echo 
echo "[INFO]: Generating keys for using the cpu command"

ssh-keygen -b 2048 -t rsa -f "${cpu_key_dir}/ssh_host_rsa_key" -q -N "" <<< y >/dev/null
ssh-keygen -b 2048 -t rsa -f "${cpu_key_dir}/cpu_rsa" -q -N "" <<< y >/dev/null

echo "[INFO]: Key generation for CPU command successfull"
