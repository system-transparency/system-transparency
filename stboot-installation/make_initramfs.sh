#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# import global configuration
source ${root}/run.config

initramfs_name="initramfs-linuxboot.cpio"
initramfs="${dir}/${initramfs_name}"
initramfs_compressed="${initramfs}.gz"
initramfs_backup="${initramfs_compressed}.backup"

gopath=$(go env GOPATH)
if [ -z "${gopath}" ]; then
    echo "GOPATH is not set!"
    echo "Please refer to https://golang.org/cmd/go/#hdr-GOPATH_environment_variable1"
    echo -e "creating initramfs $failed"; exit 1;
fi


if [ -f "${initramfs_compressed}" ]; then
    while true; do
       echo "Current Linuxboot initramfs:"
       ls -l "$(realpath --relative-to="${root}" "${initramfs_compressed}")"
       read -rp "Rebuild initramfs? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing initramfs to $(realpath --relative-to="${root}" "${initramfs_backup}")"; mv "${initramfs_compressed}" "${initramfs_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

bash "${dir}/build_security_config.sh"

echo "[INFO]: update timstamp in security_configuration.json to $(date +%s)"
jq '.build_timestamp = $newVal' --argjson newVal "$(date +%s)" "${dir}"/files-initramfs/security_configuration.json > tmp.$$.json && mv tmp.$$.json "${dir}"/files-initramfs/security_configuration.json || { echo "Cannot update timestamp in security_configuration.json. Creating initramfs $failed";  exit 1; }

bash "${dir}/build_initramfs.sh"
