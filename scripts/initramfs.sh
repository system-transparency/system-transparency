#!/usr/bin/env bash

set -Eeuo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

default_name="initramfs-linuxboot.cpio.gz"
output=

while [ $# -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --output|-o)
      if test $# -gt 0; then
        j="$1"; shift 1
        output="$j"
      else
        >&2 echo "no output file specified"
        exit 1
      fi
      ;;
    --host-config|-h)
      if test $# -gt 0; then
        j="$1"; shift 1
        host_config="$j"
      else
        >&2 echo "no host config specified"
        >&2 echo "(--host-config <config>)"
        exit 1
      fi
      ;;
    --security-config|-s)
      if test $# -gt 0; then
        j="$1"; shift 1
        security_config="$j"
      else
        >&2 echo "no security config specified"
        >&2 echo "(--security-config <config>)"
        exit 1
      fi
      ;;
    --include-dir|-i)
      if test $# -gt 0; then
        j="$1"; shift 1
        include_dir="$j"
      else
        >&2 echo "no include dir specified"
        >&2 echo "(--include-dir <dir>)"
        exit 1
      fi
      ;;
    *)
      break
      ;;
  esac
done

# append filename if not defined
if [[ -z "${output}" ]] || [[ "${output}" == */ ]];
then
  output="${output}${default_name}"
fi

if [[ -z "${security_config}" ]];
then
  >&2 echo "no security config specified"
  >&2 echo "(--security-config <config>)"
  exit 1
fi

if [[ -z "${host_config}" ]];
then
  >&2 echo "no host config specified"
  >&2 echo "(--host-config <config>)"
  exit 1
fi

if [[ ! -f "${security_config}" ]];
then
  >&2 echo "security config \"${security_config}\" does not exist"
  exit 1
fi

if [[ ! -f "${host_config}" ]];
then
  >&2 echo "host config \"${host_config}\" not found"
  exit 1
fi

if [[ -z "${include_dir}" ]];
then
  include_dir="."
fi

if [[ ! -d "${include_dir}" ]];
then
  >&2 echo "\"${include_dir}\" directory not found"
  exit 1
fi

mkdir -p "$(dirname "${output}")"

########################################

signing_root="${ST_SIGNING_ROOT}"
signing_root_name="ospkg_signing_root.pem"
https_roots="${include_dir}/https_roots.pem"
cpu_keys="${root}/out/keys/cpu_keys"
variant=${ST_LINUXBOOT_VARIANT}

# cache stderr in a file to run silently on success
rc=0
stderr_log=$(mktemp)
trap "rm ${stderr_log}" EXIT

if [[ ! -z "${GOPATH}" ]];
then
  export GOPATH
  export PATH="${GOPATH}/bin:${PATH}"
fi


case $variant in
"minimal" )
    echo "Creating minimal initramfs including stboot only"
    u-root -build=bb -uinitcmd=stboot -defaultsh="" -o "${output%.*}.tmp" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${host_config}:etc/$(basename "${host_config}")" \
    -files "${signing_root}:etc/${signing_root_name}" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/system-transparency/stboot 2>${stderr_log} || rc=$?
    ;;
"debug" )
    echo "[INFO]: creating initramfs including debugging tools"
    u-root -build=bb -uinitcmd=stboot -o "${output%.*}.tmp" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${host_config}:etc/$(basename "${host_config}")" \
    -files "${signing_root}:etc/${signing_root_name}" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    -files "${include_dir}/netsetup.elv:netsetup.elv" \
    -files "${include_dir}/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpucpio -idv < tree.cpio_rsa.pub" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/core/elvish \
    github.com/u-root/cpu/cmds/cpud \
    github.com/system-transparency/stboot 2>${stderr_log} || rc=$?
    ;;
"full" )
    echo "Creating initramfs including all u-root core tools"
    u-root -build=bb -uinitcmd=stboot -o "${output%.*}.tmp" \
    -files "${security_config}:etc/$(basename "${security_config}")" \
    -files "${host_config}:etc/$(basename "${host_config}")" \
    -files "${signing_root}:etc/${signing_root_name}" \
    -files "${https_roots}:etc/$(basename "${https_roots}")" \
    -files "${include_dir}/netsetup.elv:netsetup.elv" \
    -files "${include_dir}/start_cpu.elv:start_cpu.elv" \
    -files "${cpu_keys}/ssh_host_rsa_key:etc/ssh/ssh_host_rsa_key" \
    -files "${cpu_keys}/cpu_rsa.pub:cpu_rsa.pub" \
    core \
    github.com/u-root/cpu/cmds/cpud \
    github.com/system-transparency/stboot 2>${stderr_log} || rc=$?
    ;;
* ) >&2 echo "Unknown value in ST_LINUXBOOT_VARIANT"
    exit 1
    ;;
esac

# print stderr if u-root fails
[ "$rc" -ne 0 ] && (cat ${stderr_log}>&2;exit $rc)

# TODO: support more types of compression
gzip -f "${output%.*}.tmp"
mv ${output%.*}.tmp.gz ${output}
