#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="${dir}/$(basename "${BASH_SOURCE[0]}")"
base="$(basename ${file} .sh)"
root="$(cd "${dir}/../" && pwd)"

config_path=""
if [[ $# -eq 0 ]] ; then
    echo "Path to a manifest.json must be provided"
    exit 1
else
    config_path=${1}
    [ -f ${config_path} ] || { echo "${config_path} does not exist";  exit 1; }
fi

bootball="stboot.ball"
config_dir=$(dirname "${config_path}")
config=$(basename "${config_path}")

rm -f ${config_dir}/${bootball} || { echo -e "Removing old $bootball $failed"; exit 1; }
echo "[INFO]: pack ${config}, OS-kernel and further OS artefacts into ${bootball}"

stconfig create ${config_path} || { echo -e "stconfig create $failed"; exit 1; }

echo "[INFO]: sign $bootball with example keys"
stconfig sign $config_dir/$bootball ${root}/keys/signing-key-1.key ${root}/keys/signing-key-1.cert || { echo -e "stconfig sign $failed"; exit 1; }
stconfig sign $config_dir/$bootball ${root}/keys/signing-key-2.key ${root}/keys/signing-key-2.cert || { echo -e "stconfig sign $failed"; exit 1; }
stconfig sign $config_dir/$bootball ${root}/keys/signing-key-3.key ${root}/keys/signing-key-3.cert || { echo -e "stconfig sign $failed"; exit 1; }

echo ""
echo "[INFO]: $bootball:"
ls -l $config_dir/$bootball
