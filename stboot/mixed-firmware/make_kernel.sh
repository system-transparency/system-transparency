#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config

out="${dir}/vmlinuz-linuxboot"
kernel_version=${ST_MIXED_FIRMWARE_LINUXBOOT_KERNEL_VERSION}
kernel_config=${ST_MIXED_FIRMWARE_LINUXBOOT_KERNEL_CONFIG}

bash "${root}/stboot/make_kernel.sh" "${kernel_config}" "${out}" "${kernel_version}"

trap - EXIT
