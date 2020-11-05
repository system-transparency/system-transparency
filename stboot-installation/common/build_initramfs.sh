#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config

out="${root}/out/stboot-installation"
name="initramfs-linuxboot.cpio"
initramfs="${out}/${name}"
initramfs_compressed="${initramfs}.gz"
initramfs_backup="${initramfs_compressed}.backup"
security_config="${out}/security_configuration.json"
include_dir="${root}/stboot-installation/initramfs-includes"
https_roots="${include_dir}/https_roots.pem"
cpu_keys="${out}/keys/cpu_keys"

variant=${ST_LINUXBOOT_VARIANT}

gopath=$(go env GOPATH)
if [ -z "${gopath}" ]; then
    echo "GOPATH is not set!"
    echo "Please refer to https://golang.org/cmd/go/#hdr-GOPATH_environment_variable1"
    echo -e "creating initramfs $failed"; exit 1;
fi

if [ -f "${initramfs_compressed}" ]; then
    echo
    echo "[INFO]: backup existing initramfs to $(realpath --relative-to="${root}" "${initramfs_backup}")"
    mv "${initramfs_compressed}" "${initramfs_backup}"
fi

if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

case $variant in
"minimal" )
    echo
    echo "[INFO]: creating minimal initramfs including stboot only"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -defaultsh="" -o "${initramfs}" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/boot/stboot
    ;;
"debug" )
    echo
    echo "[INFO]: creating initramfs including debugging tools"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -o "${initramfs}" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    -files "${include_dir}/netsetup.elv:root/netsetup.elv" \
    -files "${include_dir}/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpucpio -idv < tree.cpio_rsa.pub" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/core/elvish \
    github.com/u-root/cpu/cmds/cpud \
    github.com/u-root/u-root/cmds/boot/stboot
    ;;
"full" )
    echo
    echo "[INFO]: creating initramfs including all u-root core tools"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -o "${initramfs}" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    -files "${include_dir}/netsetup.elv:root/netsetup.elv" \
    -files "${include_dir}/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpu_rsa.pub" \
    core \
    github.com/u-root/cpu/cmds/cpud \
    github.com/u-root/u-root/cmds/boot/stboot
    ;;
* ) echo "Unknown value in ST_LINUXBOOT_VARIANT";;
esac

gzip -f "${initramfs}"
