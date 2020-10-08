#! /bin/bash 

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# import global configuration
source ${root}/run.config

gopath="$(go env GOPATH)"
if [ -z "${gopath}" ]; then
    echo "GOPATH is not set!"
    echo "Please refer to https://golang.org/cmd/go/#hdr-GOPATH_environment_variable1"
    exit 1
fi

#TODO: check if GOPATH/bin is in PATH

uroot_repo="github.com/u-root/u-root"
uroot_src="${gopath}/src/${uroot_repo}"
uroot_branch=${ST_UROOT_DEV_BRANCH}
cpu_repo="github.com/u-root/cpu"

echo "[INFO]: unsing GOPATH ${gopath}"

GO111MODULE=off GOPATH="${gopath}" go get -u -v github.com/u-root/u-root

cd "${uroot_src}"
echo "[INFO]: switch to branch ${uroot_branch}"
git checkout --quiet "${uroot_branch}" 
git status
echo
echo "[INFO]: install u-root for initramfs generation"
echo "[INFO]: GO111MODULE=off"
GO111MODULE=off GOPATH="${gopath}" go install "${uroot_src}"
echo
echo "[INFO]: install stmanager to handle bootballs"
echo "[INFO]: GO111MODULE=off"
GO111MODULE=off GOPATH="${gopath}" go install "${uroot_src}/tools/stmanager"
cd "${dir}"

echo
echo "[INFO]: install cpu command for debugging"
echo "[INFO]: GO111MODULE=auto"
GO111MODULE=auto GOPATH="${gopath}" go get -u -v "${cpu_repo}/cmds/cpu" "${cpu_repo}/cmds/cpud"

echo
echo "[INFO]: install ACM grebber"
echo "[INFO]: GO111MODULE=auto"
GO111MODULE=auto GOPATH="${gopath}" go get -u -v github.com/system-transparency/sinit-acm-grebber
