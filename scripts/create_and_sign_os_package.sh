#!/bin/bash

set -o errexit
set -o pipefail
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

gopath="${GOPATH:-${root}/cache/go}"

# import global configuration
source "${DOTCONFIG:-.config}"

out="${root}/out/os-packages"
signing_key_dir="${root}/out/keys/signing_keys"
local_boot_order_file_name="local_boot_order"
local_boot_order_file="${out}/${local_boot_order_file_name}"
os_pkg_label="${ST_OS_PKG_LABEL}"
os_pkg_url="${ST_OS_PKG_URL}"
os_pkg_kernel="${ST_OS_PKG_KERNEL}"
os_pkg_initramfs="${ST_OS_PKG_INITRAMFS}"
os_pkg_cmdline="${ST_OS_PKG_CMDLINE}"
os_pkg_tboot="${ST_OS_PKG_TBOOT}"
os_pkg_tboot_args="${ST_OS_PKG_TBOOT_ARGS}"
os_pkg_acm="${ST_OS_PKG_ACM}"

output_name="os-pkg-example-$(date +"%Y-%m-%d-%H-%M-%S").zip"
output_path="${out}/${output_name}"


if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

echo "[INFO]: call '${gopath}/bin/stmanager create' to pack boot files into an OS package."

stmanager_create_args=( "--out=${output_path}" "--label=${os_pkg_label}" "--kernel=${os_pkg_kernel}" "--cmd=${os_pkg_cmdline}" "--tcmd=${os_pkg_tboot_args}")
[ -z "${os_pkg_initramfs}" ] || stmanager_create_args+=( "--initramfs=${os_pkg_initramfs}" )
[ -z "${os_pkg_tboot}" ] || stmanager_create_args+=( "--tboot=${os_pkg_tboot}" )
[ -z "${os_pkg_acm}" ] || stmanager_create_args+=( "--acm=${os_pkg_acm}" )
[ -z "${os_pkg_url}" ] || stmanager_create_args+=( "--url=${os_pkg_url}" )

"${gopath}"/bin/stmanager create "${stmanager_create_args[@]}"

echo "[INFO]: created OS package ${output_name}"
os_pkg="${output_path}"


echo "[INFO]: call 'stmanager sign' to sign $output_name with example keys"
for I in 1 2 3
do
    "${gopath}"/bin/stmanager sign --key="${signing_key_dir}/signing-key-${I}.key" --cert="${signing_key_dir}/signing-key-${I}.cert" "$os_pkg"
done

# local boot order configuration
echo
echo "[INFO]: Checking ${local_boot_order_file_name} file"
if [ -f "${local_boot_order_file}" ]; then
    echo "[INFO]: Current ${local_boot_order_file_name}"
    cat "${local_boot_order_file}"
    while true; do
        echo 
        read -rp "Reset ${local_boot_order_file_name} to default (revers alphabetical order)? (y/n)" yn
        case $yn in
            [Yy]* ) rm "${local_boot_order_file}"; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done 
fi
if [ ! -f "${local_boot_order_file}" ]; then 
    bash "${root}/stboot-installation/common/build_default_local_boot_order.sh"
fi

# hotfix for upload script
cp "${os_pkg}" "${root}/.newest-ospkg.zip"

echo ""
echo "[INFO]: $(realpath --relative-to="${root}" "$os_pkg") created and signed with example keys."
echo "[INFO]: You can use stmanager manually, too. Try '${gopath}/bin/stmanager --help'"
echo "[INFO]: Edit ${local_boot_order_file} to change boot order for local boot method"
