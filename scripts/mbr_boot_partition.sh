#!/usr/bin/env bash

set -Eeuo pipefail

default_name="mbr_boot_partition.vfat"
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
    --syslinux-dir)
      if test $# -gt 0; then
        j="$1"; shift 1
        syslinux_dir="$j"
      else
        >&2 echo "no syslinux directory specified"
        exit 1
      fi
      ;;
    --syslinux-config)
      if test $# -gt 0; then
        j="$1"; shift 1
        syslinux_config="$j"
      else
        >&2 echo "no syslinux config specified"
        >&2 echo "(--syslinux-config <config>)"
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
        j>&2 echo "(--kernel <kernel>)"
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

if [[ -z "${syslinux_config}" ]];
then
  >&2 echo "no syslinux config specified"
  >&2 echo "(--syslinux-config <config>)"
  exit 1
fi

if [[ -z "${host_config}" ]];
then
  >&2 echo "no host config specified"
  >&2 echo "(--host-config <config>)"
  exit 1
fi

if [[ ! -f "${syslinux_config}" ]];
then
  >&2 echo "syslinux config \"${syslinux_config}\" not found"
  exit 1
fi

if [[ ! -f "${host_config}" ]];
then
  >&2 echo "host config \"${host_config}\" not found"
  exit 1
fi

mkdir -p "$(dirname "${output}")"

########################################

syslinux_e32="${syslinux_dir}/efi32/com32/elflink/ldlinux/ldlinux.e32"
syslinux_efi32="${syslinux_dir}/efi32/efi/syslinux.efi" 
efi32_name="BOOTIA32.EFI"
syslinux_e64="${syslinux_dir}/efi64/com32/elflink/ldlinux/ldlinux.e64"
syslinux_efi64="${syslinux_dir}/efi64/efi/syslinux.efi"
efi64_name="BOOTX64.EFI"

echo "Creating VFAT filesystems for STBOOT partition:"
size_vfat=$((12*(1<<20)))

echo "Using kernel: ${linuxboot_kernel}"

# mkoutput.vfat requires size as an (undefined) block-count; seem to be units of 1k
if [ -f "${output}.tmp" ]; then rm "${output}.tmp"; fi
mkfs.vfat -C -n "STBOOT" "${output}.tmp" $((size_vfat >> 10))

echo "Installing Syslinux"
mmd -i "${output}.tmp" ::boot
mmd -i "${output}.tmp" ::boot/syslinux

"${syslinux_dir}/bios/mtools/syslinux" --directory /boot/syslinux/ --install "${output}.tmp"

echo "Installing linuxboot kernel"
mcopy -i "${output}.tmp" "${linuxboot_kernel}" ::

echo "Writing syslinux config"
mcopy -i "${output}.tmp" "${syslinux_config}" ::boot/syslinux/

echo "Writing host cofiguration"
mcopy -i "${output}.tmp" "${host_config}" ::

echo "Installing EFI"
mmd -i "${output}.tmp" ::EFI
mmd -i "${output}.tmp" ::EFI/BOOT
mcopy -i "${output}.tmp" "${syslinux_e32}" ::boot/syslinux/
mcopy -i "${output}.tmp" "${syslinux_e64}" ::boot/syslinux/

echo "Installing efi32"
mcopy -i "${output}.tmp" "${syslinux_efi32}" "::/EFI/BOOT/${efi32_name}"

echo "Installing efi64"
mcopy -i "${output}.tmp" "${syslinux_efi64}" "::/EFI/BOOT/${efi64_name}"

mv ${output}{.tmp,}
