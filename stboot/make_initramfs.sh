#! /bin/bash 

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

develop=false
while getopts "d" opt; do
  case $opt in
    d)
      develop=true
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      exit 1
      ;;
  esac
done

gopath="$(go env GOPATH)"
if [ -z "${gopath}" ]; then
    echo "GOPATH is not set!"
    echo "Please refer to https://golang.org/cmd/go/#hdr-GOPATH_environment_variable1"
    echo -e "creating initramfs $failed"; exit 1;
fi

if ${develop} ; then
    echo "[INFO]: create initramfs with full tooling for development"
    GOPATH=${gopath} u-root -build=bb -o ${dir}/initramfs-linuxboot.cpio \
    -files "${dir}/include/netvars.json:netvars.json" \
    -files "${dir}/include/LetsEncrypt_Authority_X3_signed_by_X1.pem:root/LetsEncrypt_Authority_X3.pem" \
    -files "${dir}/include/netsetup.elv:root/netsetup.elv" \
    all \
    github.com/system-transparency/uinit \
    || { echo -e "creating initramfs $failed"; exit 1; }
else
    echo "[INFO]: create minimal initramf including stboot und uinit only"
    GOPATH=${gopath} u-root -build=bb -o ${dir}/initramfs-linuxboot.cpio \
    -files "${dir}/include/netvars.json:netvars.json" \
    -files "${dir}/include/LetsEncrypt_Authority_X3_signed_by_X1.pem:root/LetsEncrypt_Authority_X3.pem" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/core/elvish \
    github.com/u-root/u-root/cmds/core/ip \
    github.com/u-root/u-root/cmds/boot/stboot \
    github.com/system-transparency/uinit \
    || { echo -e "creating initramfs $failed"; exit 1; }
fi 


