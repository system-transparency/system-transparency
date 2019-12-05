#!/bin/bash 

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="${dir}/$(basename "${BASH_SOURCE[0]}")"
base="$(basename ${file} .sh)"
root="$(cd "${dir}/../" && pwd)"

gopath="$(go env GOPATH)"
if [ -z "${gopath}" ]; then
    echo "GOPATH is not set!"
    echo "Please refer to https://golang.org/cmd/go/#hdr-GOPATH_environment_variable1"
    echo -e "installing stconfig tool $failed"; exit 1;
fi
uroot_src="${gopath}/src/github.com/u-root/u-root"

echo "[INFO]: unsing GOPATH ${gopath}"
echo "[INFO]: check for source code at ${uroot_src}"
if [ ! -d "${uroot_src}" ]; then
    echo "u-root source code repository not found!"
    while true; do
       read -p "Download u-root soure code now? (y/n)" yn
       case $yn in
          [Yy]* ) GOPATH=${gopath} go get github.com/u-root/u-root; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
else
    echo "[INFO]: using repository ${uroot_src}"
fi
cd ${uroot_src}

# needs to be done as long as stboot is not merged into u-root master
echo "[INFO]: switch to stboot development branch"
git checkout --quiet stboot
git status
echo "[INFO]: install stconfig tool"
GOPATH=${gopath} go install ${uroot_src}/tools/stconfig || { echo -e "installing stconfig tool $failed"; exit 1; }
if [ ! -d ${root}/configs/ ]; then
    echo "[INFO]: make configuration direktory"
    mkdir  ${root}/configs/
fi
echo "[INFO]: configuration directory is ${root}/configs"
