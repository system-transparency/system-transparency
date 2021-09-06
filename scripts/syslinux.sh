#!/usr/bin/env bash

set -Eeuo pipefail

default_name="syslinux"
output=

while [ $# -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --output|-o)
      if test $# -gt 0; then
        j="$1"; shift 1
        output="$j"
      else
        >&2 echo "no output directory specified"
        exit 1
      fi
      ;;
    *)
      break
      ;;
  esac
done

[ -d "${output}" ] && rm -r "${output}"
mkdir -p "${output}"

########################################

VERSION="6.03"
syslinux_src="https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/"
syslinux_tar="syslinux-${VERSION}.tar.xz"

echo "[INFO]: Downloading Syslinux Bootloader v${VERSION}"
wget -q "${syslinux_src}/${syslinux_tar}" -P "${output}"
tar --strip 1 -xf "${output}/${syslinux_tar}" -C "${output}"
