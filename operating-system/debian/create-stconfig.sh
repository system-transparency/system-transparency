#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

kernel="debian-buster-amd64.vmlinuz"
kernel_backup="debian-buster-amd64.vmlinuz.backup"
initrd="debian-buster-amd64.cpio.gz"
initrd_backup="debian-buster-amd64.cpio.gz.backup"
cfg_dir="debian-buster-amd64"
cfg_file="stconfig.json"

#Check if debian config directory already exists
if [ -f "${root}/configs/${cfg_dir}/${cfg_file}" ]; then
    echo "clean config directory"
    rm -r "${root}/configs/${cfg_dir}"
fi

if [ ! -f "${dir}/docker/out/${kernel}" ] || [ ! -f "${dir}/docker/out/${initrd}" ]; then
    echo "[INFO]: Build reproducible Debian OS inside docker"
    echo "Root privileges are required"
    sudo bash "${dir}/run-docker.sh" "$(id -un)"
else
    echo "[INFO]: Current Debian OS artefacts: "
    ls -l "$(realpath --relative-to=${root} "${dir}/docker/out/${kernel}")"
    ls -l "$(realpath --relative-to=${root} "${dir}/docker/out/${initrd}")"
    while true; do
       read -rp "Update? Root privileges are required (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing kernel to $(realpath --relative-to=${root} "${dir}/docker/out/${kernel_backup}")"; sudo mv "${dir}/docker/out/${kernel}" "${dir}/docker/out/${kernel_backup}"; \
                  echo "[INFO]: backup existing initramfs to $(realpath --relative-to=${root} "${dir}/docker/out/${initrd_backup}")"; sudo mv "${dir}/docker/out/${initrd}" "${dir}/docker/out/${initrd_backup}"; \
                  sudo bash "${dir}/run-docker.sh" "$(id -un)"; break;;
          [Nn]* ) break;;
          * ) echo "Please answer yes or no.";;
       esac
    done
fi

echo "[INFO]: Copy nessesary files to config directory"
mkdir -p "${root}/configs/${cfg_dir}/kernels" && cp -v "${dir}/docker/out/${kernel}" "${root}/configs/${cfg_dir}/kernels"
mkdir -p "${root}/configs/${cfg_dir}/initrds" && cp -v "${dir}/docker/out/${initrd}" "${root}/configs/${cfg_dir}/initrds"
mkdir -p "${root}/configs/${cfg_dir}/signing" && cp -v "${root}/keys/signing_keys/root.cert" "${root}/configs/${cfg_dir}/signing"

echo "[INFO]: Create ${cfg_file} for debian boot configuration"
touch "${root}/configs/${cfg_dir}/${cfg_file}"
echo '{
  "boot_configs": [
    {
      "name": "Debian Buster reproducible",
      "kernel": "kernels/'$kernel'",
      "kernel_args": "console=tty0 console=ttyS0,115200n8 rw rdinit=/lib/systemd/systemd",
      "initramfs": "initrds/'$initrd'"
    }
  ],
  "root_cert": "signing/root.cert"
}' > "${root}/configs/${cfg_dir}/${cfg_file}"

cat "${root}/configs/${cfg_dir}/${cfg_file}"

echo "Successfully createt configs/${cfg_dir}/${cfg_file}"
