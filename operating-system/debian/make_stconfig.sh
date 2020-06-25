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

kernel="${dir}/docker/out/debian-buster-amd64.vmlinuz"
kernel_backup="${kernel}.backup"
initramfs="${dir}/docker/out/debian-buster-amd64.cpio.gz"
initramfs_backup="${initramfs}.backup"
config_dir="${root}/configs/debian-buster-amd64"
config="${config_dir}/stconfig.json"
root_cert=${ST_BOOTBALL_ROOT_CERTIFICATE}
debian_cmdline=${ST_BOOTBALL_DEBIAN_CMDLINE}


if [ -f "${config}" ]; then
    while true; do
       echo "Current Debian configuration:"
       tree "$(realpath --relative-to=${root} ${config_dir})"
       echo "$(basename ${config}): "
       cat "${config}"
       read -rp "Reset Debian Buster configuration? (y/n)" yn
       case $yn in
          [Yy]* ) rm -r ${config_dir}; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

echo "[INFO]: Check for Debian Buster boot files"
bash "${dir}/make_debian.sh"

echo
echo "[INFO]: Copy boot files into configuration directory"
mkdir -p "${config_dir}/boot"
cp -v $(realpath --relative-to=${root} ${kernel}) $(realpath --relative-to=${root} "${config_dir}/boot/")
cp -v $(realpath --relative-to=${root} ${initramfs}) $(realpath --relative-to=${root} "${config_dir}/boot/")
mkdir -p "${config_dir}/signing"
cp -v $(realpath --relative-to=${root} ${root_cert}) $(realpath --relative-to=${root} "${config_dir}/signing/")

echo "[INFO]: Create $(basename ${config}) for debian boot configuration"

cat >${config} <<EOL
{
  "boot_configs": [
    {
      "name": "Debian Buster",
      "kernel": "boot/$(basename ${kernel})",
      "kernel_args": "${debian_cmdline}",
      "initramfs": "boot/$(basename ${initramfs})"
    }
  ],
  "root_cert": "signing/$(basename ${root_cert})"
}
EOL

cat ${config}

echo
echo "Successfully created $(realpath --relative-to=${root} ${config})"
