#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OPENSSL=openssl

echo "[INFO]: create a CA and a set of 5 signing keys, certified by it"

# Root key
${OPENSSL} genrsa -f4 -out ${dir}/root.key 4096 

# Self-sign root certificate
${OPENSSL} req -new -key ${dir}/root.key -batch -subj '/CN=Test Root CA' -out ${dir}/root.cert -x509 -days 1024

# Root certificate fingerprint
${OPENSSL} base64 -d -in ${dir}/root.cert -out /tmp/rootcert
shasum -a 256 -b /tmp/rootcert

for I in 1 2 3 4 5
do
  # Gen signing key
  ${OPENSSL} genrsa -f4 -out ${dir}/signing-key-${I}.key 4096
  # Certification request
  ${OPENSSL} req -new -key ${dir}/signing-key-${I}.key -batch  -subj '/CN=Signing Key '"${I}" -out ${dir}/signing-key-${I}.req
  # Fullfil certification req
  ${OPENSSL} x509 -req -in ${dir}/signing-key-${I}.req -CA ${dir}/root.cert -CAkey ${dir}/root.key -out ${dir}/signing-key-${I}.cert -days 365 -CAcreateserial
  # Remove certification req
  rm ${dir}/signing-key-${I}.req
done

echo "root.cert:          The root CA certificate"
echo "root.key:           The root CA private key"
echo "signing-key-N.cert: The certifikate corresponding to key N"
echo "signing-key-N.key:  Key N's private key"
