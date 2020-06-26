#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config

config=${dir}/syslinux.cfg
kernel="../vmlinuz-linuxboot"
initramfs="../initramfs-linuxboot.cpio.gz"
cmdline=${ST_MIXED_FIRMWARE_LINUXBOOT_CMDLINE}

if [ -f "${config}" ]; then
    while true; do
       echo "Current Syslinux config:"
       cat "$(realpath --relative-to="${root}" "${config}")"
       read -rp "Reset Syslinux config? (y/n)" yn
       case $yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

echo 
echo "Creating $(realpath --relative-to="${root}" "${config}")"


cat >"${config}" <<EOL
DEFAULT linuxboot

LABEL linuxboot
	KERNEL ${kernel}
	APPEND ${cmdline}
	INITRD ${initramfs}
EOL
