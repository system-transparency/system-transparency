#!/bin/sh

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="${dir}/$(basename "${BASH_SOURCE[0]}")"
base="$(basename ${file} .sh)"
root="$(cd "${dir}/../../" && pwd)"

kernel="debian-buster-amd64.vmlinuz"
initrd="debian-buster-amd64.cpio.gz"

echo "____Build docker image____"
docker build -t debos ${dir}/docker || { echo -e "building doker image $failed"; exit 1; }
echo "____Build Debian OS reproducible via docker container____"
docker run --cap-add=SYS_ADMIN --privileged -it -v ${root}:/system-transparency/ debos || { echo -e "running doker image $failed"; exit 1; }

read -p "Type your username to own artefacts:" user
chown -c $user:$user ${dir}/docker/out/${kernel}
chown -c $user:$user ${dir}/docker/out/${initrd}

echo "Kernel and Initramfs generated at: ${dir}/docker/out"

