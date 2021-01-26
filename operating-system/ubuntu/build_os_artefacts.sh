#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"


version=$1
out="${root}/out/operating-system"
kernel_name="debian-buster-amd64.vmlinuz"
if [ "${version}" = 18 ]; then kernel_name="ubuntu-bionic-amd64.vmlinuz"; fi
if [ "${version}" = 20 ]; then kernel_name="ubuntu-focal-amd64.vmlinuz"; fi
kernel="${out}/${kernel_name}"
kernel_backup="${kernel}.backup"
if [ "${version}" = 18 ]; then initramfs_name="ubuntu-bionic-amd64.cpio.gz"; fi
if [ "${version}" = 20 ]; then initramfs_name="ubuntu-focal-amd64.cpio.gz"; fi
initramfs="${out}/${initramfs_name}"
initramfs_backup="${initramfs}.backup"
initramfs_backup="${initramfs}.backup"
docker_image="debos-ubuntu:system-transparency"

echo ""
if [ -f "${kernel}" ]; then  
   echo
   echo "[INFO]: backup existing files to $(realpath --relative-to="${root}" "${kernel_backup}")"
   mv "${kernel}" "${kernel_backup}"
fi
if [ -f "${initramfs}" ]; then  
   echo
   echo "[INFO]: backup existing files to $(realpath --relative-to="${root}" "${initramfs_backup}")"
   mv "${initramfs}" "${initramfs_backup}"
fi


echo ""
echo "[INFO]: Build Ubuntu ${version} via debos in a docker container"
echo ""
docker run --network=host --env DEBOS_USER_ID="$(id -u)" --env DEBOS_GROUP_ID="$(id -g)" --cap-add=SYS_ADMIN --security-opt apparmor:unconfined --security-opt label:disable -it --volume "${root}:/system-transparency-root/:z" ${docker_image} "${version}"

echo
echo "Ubuntu kernel created at: $(realpath --relative-to="${root}" "${kernel}")"
echo "Ubuntu initramfs created at: $(realpath --relative-to="${root}" "${initramfs}")"

trap - EXIT
