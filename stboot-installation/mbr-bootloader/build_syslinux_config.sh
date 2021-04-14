#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

out="${root}/out/stboot-installation/mbr-bootloader"
config="${out}/syslinux.cfg"
kernel="/linuxboot.vmlinuz"

if [ ! -d "${out}" ]; then mkdir -p "${out}"; fi

echo 
echo "[INFO]: Creating $(realpath --relative-to="${root}" "${config}")"

cat >"${config}" <<EOL
DEFAULT linuxboot

LABEL linuxboot
	KERNEL ${kernel}
EOL

cat "$(realpath --relative-to="${root}" "${config}")"

trap - EXIT
