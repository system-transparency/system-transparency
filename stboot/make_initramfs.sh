#! /bin/bash 

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

var_file="hostvars.json"
https_roots_file="https-root-certificates.pem"
prov_servers_file="provisioning-servers.json"
ntp_server_file="ntp-servers.json"

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

[ -f "${dir}/include/${var_file}" ] || { echo "${dir}/include/${var_file} does not exist"; echo "Cannot include ${var_file}. Creating initramfs $failed";  exit 1; }

echo "[INFO]: update timstamp in hostvars.json to "$(date +%s)""
jq '.build_timestamp = $newVal' --argjson newVal $(date +%s) ${dir}/include/hostvars.json > tmp.$$.json && mv tmp.$$.json ${dir}/include/hostvars.json || { echo "Cannot update timestamp in hostvars.json. Creating initramfs $failed";  exit 1; }

if "${develop}" ; then
    echo "[INFO]: create initramfs with full tooling for development"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -o "${dir}/initramfs-linuxboot.cpio" \
    -files "${dir}/include/${var_file}:etc/${var_file}" \
    -files "${dir}/data/https-root-certificates.pem:root/${https_roots_file}" \
    -files "${dir}/data/provisioning-servers.json:root/${prov_servers_file}" \
    -files "${dir}/data/ntp-servers.json:root/${ntp_server_file}" \
    -files "${dir}/include/netsetup.elv:root/netsetup.elv" \
    core \
    github.com/u-root/u-root/cmds/boot/stboot \
    || { echo -e "creating initramfs $failed"; exit 1; }
else
    echo "[INFO]: create minimal initramf including stboot only"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -o "${dir}/initramfs-linuxboot.cpio" \
    -files "${dir}/include/${var_file}:etc/${var_file}" \
    -files "${dir}/data/https-root-certificates.pem:root/${https_roots_file}" \
    -files "${dir}/data/provisioning-servers.json:root/${prov_servers_file}" \
    -files "${dir}/data/ntp-servers.json:root/${ntp_server_file}" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/core/elvish \
    github.com/u-root/u-root/cmds/boot/stboot \
    || { echo -e "creating initramfs $failed"; exit 1; }
fi 


