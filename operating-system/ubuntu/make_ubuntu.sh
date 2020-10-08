#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# This determines the Ubuntu version which will be build. 
# Supply this value by a argument to the script of load it via run.config
#--------------------------------------------------------------------------
UBUNTU_VERSION="18"
#--------------------------------------------------------------------------

if [ $UBUNTU_VERSION = 20 ]
then
   kernel="${dir}/docker/out/vmlinuz-5.4.0-26-generic"
   initramfs="${dir}/docker/out/initrd.img-5.4.0-26-generic"
else
   kernel="${dir}/docker/out/vmlinuz-4.15.0-20-generic"
   initramfs="${dir}/docker/out/initrd.img-4.15.0-20-generic"
fi

kernel_backup="${kernel}.backup"
initramfs_backup="${initramfs}.backup"

docker_image="debos"

if [ -f "${kernel}" ] && [ -f "${initramfs}" ]; then
    while true; do
       echo "Current Ubuntu 18.04 LTS or 20.04 LTS:"
       ls -l "$(realpath --relative-to="${root}" "${kernel}")"
       ls -l "$(realpath --relative-to="${root}" "${initramfs}")"
       read -rp "Rebuild Ubuntu 20.04 LTS? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing files to $(realpath --relative-to="${root}" "$(dirname "${kernel}")")"; mv "${kernel}" "${kernel_backup}"; mv "${initramfs}" "${initramfs_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi


if docker image inspect debos > /dev/null 2> /dev/null; then
   echo "[INFO]: Using docker image"
   docker images ${docker_image}
else    
   echo "[INFO]: Build docker image for debos"
   echo ""
   docker build -t ${docker_image} "${dir}/docker"
fi

echo ""
echo "[INFO]: Build Ubuntu via debos in a docker container"
echo ""
docker run --env DEBOS_USER_ID=$(id -u) --env DEBOS_GROUP_ID=$(id -g) --cap-add=SYS_ADMIN --security-opt apparmor:unconfined --security-opt label:disable -it -v "${root}:/system-transparency/:z" ${docker_image} $UBUNTU_VERSION

echo
echo "Ubuntu initramfs created at: $(realpath --relative-to="${root}" "${initramfs}")"
echo "Ubuntu kernel created at: $(realpath --relative-to="${root}" "${kernel}")"
