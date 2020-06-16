#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"


lnxbt_kernel="${dir}/stboot.efi"
kernel_src="https://cdn.kernel.org/pub/linux/kernel/v5.x"
kernel_ver="linux-5.4.45"
kernel_config="${dir}/stboot_linuxboot_efistub.defconfig"

user_name="$1"

if ! id "${user_name}" >/dev/null 2>&1
then
   echo "User ${user_name} does not exist"
   exit 1
fi

bash "${root}/stboot/make_kernel.sh" "${kernel_config}" "${lnxbt_kernel}" "${kernel_src}" "${kernel_ver}"

cd "${dir}"

echo ""
echo "Successfully created $(realpath --relative-to=${root} $lnxbt_kernel) ($kernel_ver)"
echo "Any config changes you may have made via menuconfig are saved to:"
echo "$(realpath --relative-to=${root} ${kernel_config}.modified)"
