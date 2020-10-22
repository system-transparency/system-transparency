#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# import global configuration
source ${root}/run.config

mem=${ST_QEMU_MEM}
image="${root}/stboot-installation/mbr-bootloader/stboot_mbr_installation.img"

i=0
while [ -d /tmp/mytpm$i ]; do
  let i=i+1
done
tpm=/tmp/mytpm$i

mkdir $tpm

if [ -z "${XDG_CONFIG_HOME:-}" ]; then
  export XDG_CONFIG_HOME=~/.config
fi

if [ ! -f "${XDG_CONFIG_HOME}/swtpm-localca.conf" ]; then
  cat <<EOF > "${XDG_CONFIG_HOME}/swtpm-localca.conf"
statedir = ${XDG_CONFIG_HOME}/var/lib/swtpm-localca
signingkey = ${XDG_CONFIG_HOME}/var/lib/swtpm-localca/signkey.pem
issuercert = ${XDG_CONFIG_HOME}/var/lib/swtpm-localca/issuercert.pem
certserial = ${XDG_CONFIG_HOME}/var/lib/swtpm-localca/certserial
EOF
fi

if [ ! -f "${XDG_CONFIG_HOME}/swtpm-localca.options" ]; then
  cat <<EOF > "${XDG_CONFIG_HOME}/swtpm-localca.options"
--platform-manufacturer SystemTransparency
--platform-version 2.12
--platform-model QEMU
EOF
fi

if [ ! -f "${XDG_CONFIG_HOME}/swtpm_setup.conf" ]; then
   cat <<EOF > "${XDG_CONFIG_HOME}/swtpm_setup.conf"
# Program invoked for creating certificates
create_certs_tool= /usr/share/swtpm/swtpm-localca
create_certs_tool_config = ${XDG_CONFIG_HOME}/swtpm-localca.conf
create_certs_tool_options = ${XDG_CONFIG_HOME}/swtpm-localca.options
EOF
fi

# Note: TPM1 needs to access tcsd as root..
swtpm_setup.sh --tpmstate $tpm --tpm2 \
  --create-ek-cert --create-platform-cert --lock-nvram

echo "Starting $tpm"
swtpm socket --tpmstate dir=$tpm --tpm2 --ctrl type=unixio,path=/$tpm/swtpm-sock &


qemu-system-x86_64 \
  -drive if=virtio,file="${image}",format=raw \
  -nographic \
  -net user,hostfwd=tcp::2222-:2222 \
  -net nic \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-pci,rng=rng0 \
  -rtc base=localtime \
  -m "${mem}" \
  -chardev socket,id=chrtpm,path=/$tpm/swtpm-sock \
  -tpmdev emulator,id=tpm0,chardev=chrtpm \
  -device tpm-tis,tpmdev=tpm0

rm -r ${tpm:?}/*
