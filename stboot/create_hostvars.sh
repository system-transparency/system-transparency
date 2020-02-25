#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

var_file="hostvars.json"
fingerprint_file="${root}/keys/rootcert.fingerprint"

dhcp=false
qemu=false
while getopts "dq" opt; do
  case $opt in
    d)
      dhcp=true
      ;;
    q)
      qemu=true
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      exit 1
      ;;
  esac
done


if [ -f "${dir}/include/${var_file}" ]; then
    while true; do
       echo "Current ${var_file}:"
       cat "${dir}/include/${var_file}"
       read -rp "Override? (y/n)" yn
       case $yn in
          [Yy]* ) rm -f "${dir}/include/${var_file}" "${dir}/${var_file}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

echo "[INFO]: Create  ${var_file} at ${dir}/include/"
touch "${dir}/include/${var_file}"
if [ "${dhcp}" = true ]; then
    echo "{
      \"host_ip\":\"\",
      \"netmask\":\"\",
      \"gateway\":\"\",
      \"dns\":\"\",
      \"bootstrap_url\":\"https://stboot.9esec.dev\",
      \"minimal_signatures_match\": 3,
      \"fingerprints\": [
        \""$(cut -d' ' -f1 ${fingerprint_file})"\"
      ],
      \"build_timestamp\": 0
    }" > "${dir}/include/${var_file}"
elif [ "${qemu}" = true ]; then
    echo "{
      \"host_ip\":\"10.0.2.15/24\",
      \"netmask\":\"\",
      \"gateway\":\"10.0.2.2/24\",
      \"dns\":\"\",
      \"bootstrap_url\":\"https://stboot.9esec.dev\",
      \"minimal_signatures_match\": 3,
      \"fingerprints\": [
        \""$(cut -d' ' -f1 ${fingerprint_file})"\"
      ],
      \"build_timestamp\": 0
    }" > "${dir}/include/${var_file}"
fi

cat "${dir}/include/${var_file}"
echo "[INFO]: build_timestamp will be updated when initramfs is beeing build"
