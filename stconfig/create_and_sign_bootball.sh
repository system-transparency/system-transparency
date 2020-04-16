#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

config_path=""
if [[ $# -eq 0 ]] ; then
    echo "Path to a stconfig.json must be provided"
    exit 1
else
    config_path=${1}
    [ -f "${config_path}" ] || { echo "${config_path} does not exist";  exit 1; }
fi

bootball_pattern="stboot.ball*"
config_dir=$(dirname "${config_path}")
config=$(basename "${config_path}")

mac=""
while true; do
    read -rp "Provide MAC address for individual host? (y/n)" yn
    case $yn in
        [Yy]* ) read -rp "Enter MAC address:" mac; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

rm -f ${config_dir}/${bootball_pattern} || { echo -e "Removing old bootball files $failed"; exit 1; }
echo "[INFO]: pack ${config} and OS boot files into bootball."

if [ -z ${mac} ]; then
    stconfig create "${config_path}" || { echo -e "stconfig create $failed"; exit 1; }
else
    stconfig create --mac="${mac}" "${config_path}" || { echo -e "stconfig create $failed"; exit 1; }
fi

files=( $config_dir/$bootball_pattern )
[ "${#files[@]}" -gt "1" ] && { echo -e "stconfig sign $failed : more then one bootbool files in ${config_dir}"; exit 1; }
bootball=${files[0]}

signing_key_dir="${root}/keys/signing_keys"

echo "[INFO]: sign $bootball with example keys"
stconfig sign --key="${signing_key_dir}/signing-key-1.key" --cert="${signing_key_dir}/signing-key-1.cert" "$bootball"|| { echo -e "stconfig sign $failed"; exit 1; }
stconfig sign --key="${signing_key_dir}/signing-key-2.key" --cert="${signing_key_dir}/signing-key-2.cert" "$bootball"|| { echo -e "stconfig sign $failed"; exit 1; }
stconfig sign --key="${signing_key_dir}/signing-key-3.key" --cert="${signing_key_dir}/signing-key-3.cert" "$bootball"|| { echo -e "stconfig sign $failed"; exit 1; }

echo ""
echo "[INFO]: $(realpath --relative-to=${root} "$bootball") created and signed with example keys."
echo "[INFO]: You can use stconfig manually, too. Try 'stconfig --help'"
