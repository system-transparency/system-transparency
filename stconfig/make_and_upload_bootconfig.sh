#!/bin/bash

set -o errexit
set -o pipefail
# set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="${dir}/$(basename "${BASH_SOURCE[0]}")"
base="$(basename ${file} .sh)"
root="$(cd "${dir}/../" && pwd)"

server="mullvad.9esec.io"
bootfile="stboot.zip"
if [[ $# -eq 0 ]] ; then
    echo "Path to a manifest.json must be provided"
    exit 1
else
    manifest_path=${1}
fi

config_dir=$(dirname "${manifest_path}")
manifest=$(basename "${manifest_path}")

echo "[INFO]: cleaning up $server"
rm -f ${config_dir}/${bootfile} || { echo -e "Removing old $bootfile $failed"; exit 1; }
ssh -t root@$server 'rm -f /var/www/testdata/bc.zip; exit' || { echo -e "Removing old $bootfile on $server $failed"; exit 1; }

echo "[INFO]: pack manifest.json, OS-kernel and further OS artefacts into ${bootfile}"

stconfig create ${manifest_path} -o ${config_dir}/${bootfile} || { echo -e "stconfig create $failed"; exit 1; }

echo "[INFO]: sign $bootfile with example keys"
stconfig sign $config_dir/$bootfile ${root}/keys/signing-key-1.key ${root}/keys/signing-key-1.cert || { echo -e "stconfig sign $failed"; exit 1; }
stconfig sign $config_dir/$bootfile ${root}/keys/signing-key-2.key ${root}/keys/signing-key-2.cert || { echo -e "stconfig sign $failed"; exit 1; }
stconfig sign $config_dir/$bootfile ${root}/keys/signing-key-3.key ${root}/keys/signing-key-3.cert || { echo -e "stconfig sign $failed"; exit 1; }

echo "[INFO]: upload ${config_dir}/${bootfile} to ${server}"
scp $config_dir/$bootfile root@$server:/var/www/testdata/ || { echo -e "upload via scp $failed"; exit 1; }
echo "[INFO]: successfully uploaded signed $bootfile to $server"
