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

kernel_out="${root}/out/stboot-installation/mbr-bootloader/linuxboot.vmlinuz"
kernel_version=${ST_MBR_BOOTLOADER_KERNEL_VERSION}
kernel_config=${ST_MBR_BOOTLOADER_KERNEL_CONFIG}
cmdline=${ST_LINUXBOOT_CMDLINE}


bash "${root}/stboot-installation/build_security_config.sh"

echo "[INFO]: update timstamp in security_configuration.json to $(date +%s)"
jq '.build_timestamp = $newVal' --argjson newVal "$(date +%s)" "${root}/out/stboot-installation/security_configuration.json" > tmp.$$.json && mv tmp.$$.json "${root}/out/stboot-installation/security_configuration.json" || { echo "Cannot update timestamp in security_configuration.json.";  exit 1; }

bash "${root}/stboot-installation/build_initramfs.sh"

echo
echo "[INFO]: Patching kernel configuration to include configured command line:"
echo "cmdline: ${cmdline}"
cp "${kernel_config}" "${kernel_config}.patch"
sed -i "s/CONFIG_CMDLINE=.*/CONFIG_CMDLINE=\"${cmdline}\"/" "${kernel_config}.patch"

bash "${root}/stboot-installation/build_kernel.sh" "${root}/${kernel_config}" "${kernel_out}" "${kernel_version}"

bash "${dir}/build_syslinux_config.sh"

bash "${root}/stboot-installation/build_host_config.sh"

bash "${dir}/build_image.sh"

trap - EXIT