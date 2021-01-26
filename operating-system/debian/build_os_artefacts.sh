#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

out="${root}/out/operating-system"
kernel_name="debian-buster-amd64.vmlinuz"
kernel="${out}/${kernel_name}"
kernel_backup="${kernel}.backup"
initramfs_name="debian-buster-amd64.cpio.gz"
initramfs="${out}/${initramfs_name}"
initramfs_backup="${initramfs}.backup"
docker_image="debos-debian:system-transparency"

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
echo "[INFO]: Build reproducible Debian Buster via debos in a docker container"
echo ""
docker run --network=host --env DEBOS_USER_ID="$(id -u)" --env DEBOS_GROUP_ID="$(id -g)" --cap-add=SYS_ADMIN --security-opt apparmor:unconfined -it --volume "${root}:/system-transparency-root:z" ${docker_image}

echo
echo "Debian kernel created at: $(realpath --relative-to="${root}" "${kernel}")"
echo "Debian initramfs created at: $(realpath --relative-to="${root}" "${initramfs}")"

trap - EXIT

