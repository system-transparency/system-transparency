#!/usr/bin/env bash

set -Eeuo pipefail

default_name="syslinux.cfg"
default_kernel="linuxboot.vmlinuz"
output=
kernel=

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
    --kernel|-k)
      if test $# -gt 0; then
        j="$1"; shift 1
        kernel="$j"
      else
        >&2 echo "no kernel file name specified"
        >&2 echo "(--kernel <kernel_name>"
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

if [[ -z "${kernel}" ]];
then
  kernel="${default_kernel}"
fi

mkdir -p "$(dirname "${output}")"

########################################

cat <<EOF > "${output}"
DEFAULT linuxboot

LABEL linuxboot
	KERNEL ${kernel}
EOF
