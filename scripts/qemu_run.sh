#!/usr/bin/env bash

set -Eeuo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

ospkg_dir="$ST_LOCAL_OSPKG_DIR"
boot_mode="$ST_BOOT_MODE"

image=
boot=mbr
python_http_server="python3 -m http.server 8080"
ovmf=
ovmf_locs=("/usr/share/OVMF/OVMF_CODE.fd" "/usr/share/edk2/ovmf/OVMF_CODE.fd" "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd")
declare -a qemu_args

function locate_ovmf {
  for i in "${ovmf_locs[@]}"
  do
    if [ -f "$i" ]; then
      ovmf="$i"
      return 0
    fi
  done
  if [ "$ovmf" == "" ]; then
    >&2 echo "ERROR: OVMF not found"
    return 1
  fi
}

while [ $# -gt 0 ]; do
  i="$1"; shift 1
  case "$i" in
    --image|-i)
      if test $# -gt 0; then
        j="$1"; shift 1
        image="$j"
      else
        >&2 echo "no image file specified"
        >&2 echo "(--image <image>)"
        exit 1
      fi
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z "${image}" ]];
then
  >&2 echo "usage: $0 --image <stboot-image>"
  exit 1
fi

locate_ovmf
qemu_args+=("-bios" "${ovmf}")

cleanup () {
  http_pid=$(pgrep -f "$python_http_server")
  [ -z "$http_pid" ] || kill -TERM "${http_pid}"
  pkill -TERM -P $$
  [ -z "$tpm" ] || rm -r $tpm
}

trap cleanup 0

case "$boot_mode" in
  local)
    ;;
  network)
    if [ -d "$ospkg_dir" ];then
      (cd $ospkg_dir && $python_http_server) &
    else
      echo "OS Package directory $ospkg_dir required"
      exit 1
    fi
      ;;
    *)
    >&2 echo "unknown boot mode: $boot_mode"
    exit 1
esac


########################################

mem=4G
swtpm_dir=${root}/cache/swtpm
tpm=$(mktemp -d --suffix='-tpm')

mkdir -p "${swtpm_dir}"

if [ ! -f "${swtpm_dir}/swtpm-localca.conf" ]; then
  cat <<EOF > "${swtpm_dir}/swtpm-localca.conf"
statedir = ${swtpm_dir}/var/lib/swtpm-localca
signingkey = ${swtpm_dir}/var/lib/swtpm-localca/signkey.pem
issuercert = ${swtpm_dir}/var/lib/swtpm-localca/issuercert.pem
certserial = ${swtpm_dir}/var/lib/swtpm-localca/certserial
EOF
fi

if [ ! -f "${swtpm_dir}/swtpm-localca.options" ]; then
  cat <<EOF > "${swtpm_dir}/swtpm-localca.options"
--platform-manufacturer SystemTransparency
--platform-version 2.12
--platform-model QEMU
EOF
fi

if [ ! -f "${swtpm_dir}/swtpm_setup.conf" ]; then
   cat <<EOF > "${swtpm_dir}/swtpm_setup.conf"
# Program invoked for creating certificates
create_certs_tool= /usr/share/swtpm/swtpm-localca
create_certs_tool_config = ${swtpm_dir}/swtpm-localca.conf
create_certs_tool_options = ${swtpm_dir}/swtpm-localca.options
EOF
fi

swtpm_setup --tpmstate $tpm --tpm2 --config ${swtpm_dir}/swtpm_setup.conf \
  --create-ek-cert --create-platform-cert --lock-nvram

echo "Starting $tpm"
swtpm socket --tpmstate dir=$tpm --tpm2 --ctrl type=unixio,path=/$tpm/swtpm-sock &

# use kvm if avaiable
if [[ -w /dev/kvm ]]; then
qemu_args+=("-enable-kvm")
fi

qemu-system-x86_64 \
  -M q35 \
  -drive if=virtio,file="${image}",format=raw \
  -net user,hostfwd=tcp::2222-:2222 \
  -net nic \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-pci,rng=rng0 \
  -rtc base=localtime \
  -m "${mem}" \
  -chardev socket,id=chrtpm,path=/$tpm/swtpm-sock \
  -tpmdev emulator,id=tpm0,chardev=chrtpm \
  -device tpm-tis,tpmdev=tpm0 \
  -nographic \
  "${qemu_args[@]}"
