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

kernel_out="${root}/out/stboot-installation/efi-application/linuxboot.efi"
kernel_version=${ST_EFI_APPLICATION_EFISTUB_KERNEL_VERSION}
kernel_config=${ST_EFI_APPLICATION_EFISTUB_KERNEL_CONFIG}
cmdline=${ST_LINUXBOOT_CMDLINE}

bash "${root}/stboot-installation/build_initramfs.sh"

echo
echo "[INFO]: Patching kernel configuration to include configured command line:"
echo "cmdline: ${cmdline}"
cp "${kernel_config}" "${kernel_config}.patch"
sed -i "s/CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${cmdline}\"/" "${kernel_config}.patch"

bash "${root}/stboot-installation/build_kernel.sh" "${root}/${kernel_config}" "${kernel_out}" "${kernel_version}"

bash "${root}/stboot-installation/build_host_config.sh"

bash "${dir}/build_image.sh"

trap - EXIT