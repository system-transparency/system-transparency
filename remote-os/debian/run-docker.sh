#!/bin/sh

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

if [ -d ${root}/configs/debian ]; then
    rmdir -v --ignore-fail-on-non-empty ${root}/configs/debian
fi

#Build docker image
sudo docker build -t debos ${dir}/docker || { echo -e "building doker image $failed"; exit 1; }
#Build DebianOS reproducible via docker container
sudo docker run --cap-add=SYS_ADMIN --privileged -it -v ${root}:/system-transparency/ debos || { echo -e "running doker image $failed"; exit 1; }

echo "Kernel and Initramfs generated at: ${dir}/out"

#create mainfest.json inside example directory
#./${root}/stconfig/create_manifest.sh
