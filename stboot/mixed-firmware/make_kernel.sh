#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config


lnxbt_kernel="${dir}/vmlinuz-linuxboot"
lnxbt_kernel_backup="${dir}/vmlinuz-linuxboot.backup"
kernel_src="https://cdn.kernel.org/pub/linux/kernel/v4.x"
kernel_ver="linux-4.19.6"
kernel_config=${ST_MIXED_FIRMWARE_LINUXBOOT_KERNEL_CONFIG}

bash "${root}/stboot/make_kernel.sh" ${kernel_config} ${lnxbt_kernel} ${kernel_src} ${kernel_ver}

trap - EXIT
