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
security_config_name="security_configuration.json"
security_config="${dir}/files-initramfs/${security_config_name}"
https_roots_name="https_roots.pem"
https_roots="${dir}/files-initramfs/${https_roots_name}"
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



echo "[INFO]: check for security_configuration.json"
bash "${dir}/make_security_config.sh"

echo "[INFO]: update timstamp in security_configuration.json to $(date +%s)"
jq '.build_timestamp = $newVal' --argjson newVal "$(date +%s)" "${dir}"/files-initramfs/security_configuration.json > tmp.$$.json && mv tmp.$$.json "${dir}"/files-initramfs/security_configuration.json || { echo "Cannot update timestamp in security_configuration.json. Creating initramfs $failed";  exit 1; }

case $variant in
"minimal" )
    echo "[INFO]: create minimal initramfs including stboot only"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -defaultsh="" -o "${initramfs}" \
    -files "${security_config}:etc/${security_config_name}" \
    -files "${https_roots}:etc/${https_roots_name}" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/boot/stboot
    ;;
"debug" )
    echo "[INFO]: create initramfs including debugging tools"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -o "${initramfs}" \
    -files "${security_config}:etc/${security_config_name}" \
    -files "${https_roots}:etc/${https_roots_name}" \
    -files "${dir}/files-initramfs/start_cpu.elv:start_cpu.elv" \
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
    -files "${security_config}:etc/${security_config_name}" \
    -files "${https_roots}:etc/${https_roots_name}" \
    -files "${dir}/files-initramfs/netsetup.elv:root/netsetup.elv" \
    -files "${dir}/files-initramfs/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpu_rsa.pub" \
    core \
    github.com/u-root/cpu/cmds/cpud \
    github.com/u-root/u-root/cmds/boot/stboot
    ;;
* ) echo "Unknows value in ST_LINUXBOOT_VARIANT";;
esac

gzip -f "${initramfs}"
