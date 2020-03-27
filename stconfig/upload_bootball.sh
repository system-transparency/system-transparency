#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"
server=${ST_STBOOT_SERVER:-"stboot.9esec.dev"}
server_path=${ST_STBOOT_SERVER_PATH:-"/home/provisioner/www"}
provisioner=${ST_STBOOT_PROVISIONER:-"provisioner"}

bootball=""
if [[ $# -eq 0 ]] ; then
    echo "Path to a stboot.ball file must be provided"
    exit 1
else
    bootball="${1}"
    [ -f "${bootball}" ] || { echo "${bootball} does not exist";  exit 1; }
fi

echo "[INFO]: upload ${bootball} to ${server_path} at ${server}"
scp "$bootball" "${provisioner}@$server:${server_path}/$(basename "${bootball}")" || { echo -e "upload via scp $failed"; exit 1; }
echo "[INFO]: successfully uploaded bootball"

