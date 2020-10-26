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
cmdline=${ST_LINUXBOOT_CMDLINE}

echo 
echo "Creating $(realpath --relative-to="${root}" "${config}")"


cat >"${config}" <<EOL
DEFAULT linuxboot

LABEL linuxboot
	KERNEL ${kernel}
	APPEND ${cmdline}
	INITRD ${initramfs}
EOL
