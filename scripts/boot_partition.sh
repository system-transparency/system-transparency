#!/usr/bin/env bash

set -Eeuo pipefail

default_name="efi_boot_partition.vfat"
output=
host_config=
linuxboot_kernel=

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
    --host-config)
      if test $# -gt 0; then
        j="$1"; shift 1
        host_config="$j"
      else
        >&2 echo "no host config specified"
        >&2 echo "(--host-config <config>)"
        exit 1
      fi
      ;;
    --kernel)
      if test $# -gt 0; then
        j="$1"; shift 1
        linuxboot_kernel="$j"
      else
        >&2 echo "no kernel specified"
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

if [[ -z "${linuxboot_kernel}" ]];
then
  >&2 echo "no kernel specified"
  >&2 echo "(--kernel <kernel>)"
  exit 1
fi

if [[ ! -f "${linuxboot_kernel}" ]];
then
  >&2 echo "kernel \"${linuxboot_kernel}\" not found"
  exit 1
fi

if [[ -n "${host_config}" ]] && [[ ! -f "${host_config}" ]];
then
  >&2 echo "host config \"${host_config}\" not found"
  exit 1
fi


mkdir -p "$(dirname "${output}")"

########################################

tot_size=$(du -cb ${linuxboot_kernel} | tail -1 | awk '{print $1}')

echo "Creating VFAT filesystems for STBOOT partition:"
size_vfat=$((tot_size + (1<<20)))

echo "Using kernel: ${linuxboot_kernel}"

# mkoutput.vfat requires size as an (undefined) block-count; seem to be units of 1k
if [ -f "${output}.tmp" ]; then rm "${output}.tmp"; fi

vfat_blocks=$((size_vfat >> 10))
vfat_blocks=$(((($vfat_blocks+32)&~31)))
mkfs.vfat -C -n "STBOOT" "${output}.tmp" $vfat_blocks

echo "Installing STBOOT.EFI"
mmd -i "${output}.tmp" ::EFI
mmd -i "${output}.tmp" ::EFI/BOOT

mcopy -i "${output}.tmp" "${linuxboot_kernel}" ::/EFI/BOOT/BOOTX64.EFI

if [ -n "${host_config}" ]; then
	echo "Writing host cofiguration"
	mcopy -i "${output}.tmp" "${host_config}" ::/host_configuration.json
fi

mv ${output}{.tmp,}

trap - EXIT
