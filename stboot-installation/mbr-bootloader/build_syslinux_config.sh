#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

# import global configuration
source ${root}/run.config

config=${dir}/syslinux.cfg
kernel="../vmlinuz-linuxboot"

echo 
echo "[INFO]: Creating $(realpath --relative-to="${root}" "${config}")"

cat >"${config}" <<EOL
DEFAULT linuxboot

LABEL linuxboot
	KERNEL ${kernel}
EOL

cat "$(realpath --relative-to="${root}" "${config}")"
