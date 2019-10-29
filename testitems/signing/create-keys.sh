#!/bin/bash
OPENSSL=openssl

# Errors are fatal
set -e

# Creates a CA and a set of 5 signing keys, certified by it.

# Root key
${OPENSSL} genrsa -f4 -out root.key 4096 

# Self-sign root certificate
${OPENSSL} req -new -key root.key -batch -subj '/CN=Test Root CA' -out root.cert -x509 -days 1024

# Root certificate fingerprint
${OPENSSL} base64 -d -in root.cert -out /tmp/rootcert
shasum -a 256 -b /tmp/rootcert

for I in 1 2 3 4 5
do
  # Gen signing key
  ${OPENSSL} genrsa -f4 -out signing-key-${I}.key 4096
  # Certification request
  ${OPENSSL} req -new -key signing-key-${I}.key -batch  -subj '/CN=Signing Key '"${I}" -out signing-key-${I}.req
  # Fullful certification req
  ${OPENSSL} x509 -req -in signing-key-${I}.req -CA root.cert -CAkey root.key -out signing-key-${I}.cert -days 365 -CAcreateserial
  # Remove certification req
  rm signing-key-${I}.req
done

echo "root.cert           Root CA certificate"
echo "root.key            Root CA private key"
echo "signing-key-N.cert  Signing key N (certificate)"
echo "signing-key-N.key   Signing key N's private key"
