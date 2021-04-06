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
source "${DOTCONFIG:-.config}"

out="${root}/out/stboot-installation"
name="initramfs-linuxboot.cpio"
initramfs="${out}/${name}"
initramfs_compressed="${initramfs}.gz"
initramfs_backup="${initramfs_compressed}.backup"
signing_root="${ST_SIGNING_ROOT}"
signing_root_name="ospkg_signing_root.pem"
security_config="${out}/security_configuration.json"
include_dir="${root}/stboot-installation/initramfs-includes"
https_roots="${include_dir}/https_roots.pem"
cpu_keys="${root}/out/keys/cpu_keys"

variant=${ST_LINUXBOOT_VARIANT}

gopath="${GOPATH:-${root}/cache/go}"

if [ -f "${initramfs_compressed}" ]; then
    echo
    echo "[INFO]: backup existing initramfs to $(realpath --relative-to="${root}" "${initramfs_backup}")"
    mv "${initramfs_compressed}" "${initramfs_backup}"
fi

if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

# cache stderr in a file to run silently on success
rc=0
stderr_log=$(mktemp)
trap "rm ${stderr_log}" EXIT

case $variant in
"minimal" )
    echo
    echo "[INFO]: creating minimal initramfs including stboot only"
    GOPATH="${gopath}" ${gopath}/bin/u-root -build=bb -uinitcmd=stboot -defaultsh="" -o "${initramfs}" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${signing_root}:etc/${signing_root_name}" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/boot/stboot 2>${stderr_log} || rc=$?
    ;;
"debug" )
    echo
    echo "[INFO]: creating initramfs including debugging tools"
    GOPATH="${gopath}" ${gopath}/bin/u-root -build=bb -uinitcmd=stboot -o "${initramfs}" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${signing_root}:etc/${signing_root_name}" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    -files "${include_dir}/netsetup.elv:netsetup.elv" \
    -files "${include_dir}/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpucpio -idv < tree.cpio_rsa.pub" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/core/elvish \
    github.com/u-root/cpu/cmds/cpud \
    github.com/u-root/u-root/cmds/boot/stboot 2>${stderr_log} || rc=$?
    ;;
"full" )
    echo
    echo "[INFO]: creating initramfs including all u-root core tools"
    GOPATH="${gopath}" u-root -build=bb -uinitcmd=stboot -o "${initramfs}" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${signing_root}:etc/${signing_root_name}" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    -files "${include_dir}/netsetup.elv:netsetup.elv" \
    -files "${include_dir}/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpu_rsa.pub" \
    core \
    github.com/u-root/cpu/cmds/cpud \
    github.com/u-root/u-root/cmds/boot/stboot 2>${stderr_log} || rc=$?
    ;;
* ) echo "Unknown value in ST_LINUXBOOT_VARIANT";;
esac

# print stderr if u-root fails
[ "$rc" -ne 0 ] && (cat ${stderr_log}>&2;exit $rc)

gzip -f "${initramfs}"
