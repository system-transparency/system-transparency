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

out="${dir}/stboot.efi"
kernel_src="https://cdn.kernel.org/pub/linux/kernel/v5.x"
kernel_ver="linux-5.4.45"
kernel_config=${ST_UEFI_FIRMWARE_EFISTUB_KERNEL_CONFIG}

bash "${root}/stboot/make_kernel.sh" "${kernel_config}" "${out}" "${kernel_src}" "${kernel_ver}"

trap - EXIT


