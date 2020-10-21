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

out_dir="${ST_OS_PKG_OUT}"
os_pkg_label="${ST_OS_PKG_LABEL}"
os_pkg_kernel="${ST_OS_PKG_KERNEL}"
os_pkg_initramfs="${ST_OS_PKG_INITRAMFS}"
os_pkg_cmdline="${ST_OS_PKG_CMDLINE}"
os_pkg_tboot="${ST_OS_PKG_TBOOT}"
os_pkg_tboot_args="${ST_OS_PKG_TBOOT_ARGS}"
os_pkg_acm="${ST_OS_PKG_ACM}"
os_pkg_signing_root="${ST_OS_PKG_SIGNING_ROOT}"
os_pkg_allow_non_txt="${ST_OS_PKG_ALLOW_NON_TXT}"




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

echo "[INFO]: call 'stmanager create' to pack boot files into an OS package."

stmanager_create_args=( "--out=${out_dir}" "--label=${os_pkg_label}" "--kernel=${os_pkg_kernel}" "--cmd=${os_pkg_cmdline}" "--tcmd=${os_pkg_tboot_args}" "--cert=${os_pkg_signing_root}")
[ -z "${os_pkg_initramfs}" ] || stmanager_create_args+=( "--initramfs=${os_pkg_initramfs}" )
[ -z "${os_pkg_tboot}" ] || stmanager_create_args+=( "--tboot=${os_pkg_tboot}" )
[ -z "${os_pkg_acm}" ] || stmanager_create_args+=( "--acm=${os_pkg_acm}" )
[ -z "${mac}" ] || stmanager_create_args+=( "--mac=${mac}" )
[ "${os_pkg_allow_non_txt}" = "y" ] && stmanager_create_args+=( "--unsave" )

os_pkg_name=$(stmanager create "${stmanager_create_args[@]}")
os_pkg="${out_dir}/${os_pkg_name}"

echo "[INFO]: created OS package ${os_pkg_name}."


signing_key_dir="${root}/keys/signing_keys"

echo "[INFO]: call 'stmanager sign' to sign $os_pkg with example keys"
for I in 1 2 3 4 5
do
    stmanager sign --key="${signing_key_dir}/signing-key-${I}.key" --cert="${signing_key_dir}/signing-key-${I}.cert" "$os_pkg"
done

# hotfix for upload script
cp "${os_pkg}" "${root}/.newest-ospkg.zip"

echo ""
echo "[INFO]: $(realpath --relative-to="${root}" "$os_pkg") created and signed with example keys."
echo "[INFO]: You can use stmanager manually, too. Try 'stmanager --help'"
