#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# import global configuration
source "${root}/run.config"

out_dir="${root}/bootballs/"

[ -d "${out_dir}" ] || mkdir -p "${out_dir}"

mac=""
while true; do
    read -rp "Provide MAC address for individual host? (y/n)" yn
    case $yn in
        [Yy]* ) read -rp "Enter MAC address:" mac; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "[INFO]: call 'stmanager create' to pack OS boot files into bootball."

cmdline=( "--out=${ST_BOOTBALL_OUT}" "--label=${ST_BOOTBALL_LABEL}" "--kernel=${ST_BOOTBALL_OS_KERNEL}" "--cmd=${ST_BOOTBALL_OS_CMDLINE}" "--tcmd=${ST_BOOTBALL_TBOOT_ARGS}" "--cert=${ST_BOOTBALL_ROOT_CERTIFICATE}")
[ -z "${ST_BOOTBALL_OS_INITRAMFS}" ] || cmdline+=( "--initramfs=${ST_BOOTBALL_OS_INITRAMFS}" )
[ -z "${ST_BOOTBALL_TBOOT}" ] || cmdline+=( "--tboot=${ST_BOOTBALL_TBOOT}" )
[ -z "${ST_BOOTBALL_ACM}" ] || cmdline+=( "--acm=${ST_BOOTBALL_ACM}" )
[ -z "${mac}" ] || cmdline+=( "--mac=${mac}" )
[ "${ST_BOOTBALL_ALLOW_NON_TXT}" = "y" ] && cmdline+=( "--unsave" )

bootball_name=$(stmanager create "${cmdline[@]}")
bootball="${ST_BOOTBALL_OUT}/${bootball_name}"

echo "[INFO]: created bootball ${bootball_name}."


signing_key_dir="${root}/keys/signing_keys"

echo "[INFO]: call 'stmanager sign' to sign $bootball with example keys"
for I in 1 2 3 4 5
do
    stmanager sign --key="${signing_key_dir}/signing-key-${I}.key" --cert="${signing_key_dir}/signing-key-${I}.cert" "$bootball"
done

echo ""
echo "[INFO]: $(realpath --relative-to="${root}" "$bootball") created and signed with example keys."
echo "[INFO]: You can use stmanager manually, too. Try 'stmanager --help'"
