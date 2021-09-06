#!/usr/bin/env bash

set -Eeuo pipefail

default_name="stboot_efi_installation.img"
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
    --boot|-b)
      if test $# -gt 0; then
        j="$1"; shift 1
        boot_part="$j"
      else
        >&2 echo "no boot partition file specified"
        >&2 echo "(--boot <boot partition>)"
        exit 1
      fi
      ;;
    --data|-d)
      if test $# -gt 0; then
        j="$1"; shift 1
        data_part="$j"
      else
        >&2 echo "no data partition file specified"
        >&2 echo "(--data <data partition>)"
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

if [[ -z "${boot_part}" ]];
then
  >&2 echo "no boot partition file specified"
  >&2 echo "(--boot <boot partition>)"
  exit 1
fi

if [[ -z "${data_part}" ]];
then
  >&2 echo "no data partition file specified"
  >&2 echo "(--data <data partition>)"
  exit 1
fi

if [[ ! -f "${boot_part}" ]];
then
  >&2 echo "boot partition file \"${boot_part}\" not found"
  exit 1
fi

if [[ ! -f "${data_part}" ]];
then
  >&2 echo "data partition file \"${data_part}\" not found"
  exit 1
fi


mkdir -p "$(dirname "${output}")"

########################################

alignment=1048576
#size_vfat=$((12*(1<<20)))
size_vfat=$(du -b "${boot_part}" | cut -f1)
#size_ext4=$((767*(1<<20)))
size_ext4=$(du -b "${data_part}" | cut -f1)

offset_vfat=$(( alignment/512 ))
offset_ext4=$(( (alignment + size_vfat + alignment)/512 ))

# insert the filesystem to a new file at offset 1MB
dd if="${boot_part}" of="${output}.tmp" conv=notrunc obs=512 status=none seek=${offset_vfat}
dd if="${data_part}" of="${output}.tmp" conv=notrunc obs=512 status=none seek=${offset_ext4}

# extend the file by 1MB
truncate -s "+${alignment}" "${output}.tmp"

echo "Adding partitions to disk image:"

# apply partitioning
parted -s --align optimal "${output}.tmp" mklabel gpt mkpart "STBOOT" fat32 "$((offset_vfat * 512))B" "$((offset_vfat * 512 + size_vfat))B" mkpart "STDATA" ext4 "$((offset_ext4 * 512))B" "$((offset_ext4 * 512 + size_ext4))B" set 1 boot on set 1 legacy_boot on

echo "Image layout:"
parted -s "${output}.tmp" print

mv ${output}{.tmp,}
