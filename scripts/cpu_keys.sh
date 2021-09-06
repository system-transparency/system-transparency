#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

cpu_key_dir="${root}/out/keys/cpu_keys"

mkdir -p "${cpu_key_dir}"

# SSH key generation for cpu command
echo 
echo "[INFO]: Generating keys for using u-root's cpu command"

ssh-keygen -b 2048 -t rsa -f "${cpu_key_dir}/ssh_host_rsa_key" -q -N "" <<< y >/dev/null
ssh-keygen -b 2048 -t rsa -f "${cpu_key_dir}/cpu_rsa" -q -N "" <<< y >/dev/null

echo "[INFO]: Keys generation successfull"