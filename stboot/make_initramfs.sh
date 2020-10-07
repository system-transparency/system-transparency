#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# import global configuration
source ${root}/run.config

initramfs_name="initramfs-linuxboot.cpio"
initramfs="${dir}/${initramfs_name}"
initramfs_compressed="${initramfs}.gz"
initramfs_backup="${initramfs_compressed}.backup"
hostvars_name="hostvars.json"
hostvars="${dir}/include/${hostvars_name}"
cpu_keys="${root}/keys/cpu_keys"

variant=${ST_LINUXBOOT_VARIANT}

gopath=$(go env GOPATH)
if [ -z "${gopath}" ]; then
    echo "GOPATH is not set!"
    echo "Please refer to https://golang.org/cmd/go/#hdr-GOPATH_environment_variable1"
    echo -e "creating initramfs $failed"; exit 1;
fi


if [ -f "${initramfs_compressed}" ]; then
    while true; do
       echo "Current Linuxboot initramfs:"
       ls -l "$(realpath --relative-to="${root}" "${initramfs_compressed}")"
       read -rp "Rebuild initramfs? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing initramfs to $(realpath --relative-to="${root}" "${initramfs_backup}")"; mv "${initramfs_compressed}" "${initramfs_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi



echo "[INFO]: check for hostvars.json"
bash "${dir}/make_hostvars.sh"

echo "[INFO]: update timstamp in hostvars.json to $(date +%s)"
jq '.build_timestamp = $newVal' --argjson newVal "$(date +%s)" "${dir}"/include/hostvars.json > tmp.$$.json && mv tmp.$$.json "${dir}"/include/hostvars.json || { echo "Cannot update timestamp in hostvars.json. Creating initramfs $failed";  exit 1; }

case $variant in
"minimal" )
    echo "[INFO]: create minimal initramfs including stboot only"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -defaultsh="" -o "${initramfs}" \
    -files "${hostvars}:etc/${hostvars_name}" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/boot/stboot
    ;;
"debug" )
    echo "[INFO]: create initramfs including debugging tools"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -o "${initramfs}" \
    -files "${hostvars}:etc/${hostvars_name}" \
    -files "${dir}/include/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpucpio -idv < tree.cpio_rsa.pub" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/core/elvish \
    github.com/u-root/cpu/cmds/cpud \
    github.com/u-root/u-root/cmds/boot/stboot
    ;;
"full" )
    echo "[INFO]: create initramfs including all u-root core tools"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -o "${initramfs}" \
    -files "${hostvars}:etc/${hostvars_name}" \
    -files "${dir}/include/netsetup.elv:root/netsetup.elv" \
    -files "${dir}/include/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpu_rsa.pub" \
    core \
    github.com/u-root/cpu/cmds/cpud \
    github.com/u-root/u-root/cmds/boot/stboot
    ;;
* ) echo "Unknows value in ST_LINUXBOOT_VARIANT";;
esac

gzip -f "${initramfs}"
