#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Source global build config file.
if [ $# -gt 0 ]; then
    run_config=$1; shift
    [ -r ${run_config} ] && source ${run_config}
fi

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

failed="\e[1;5;31mfailed\e[0m"

prov_server=${ST_SSH_UPLOAD_SERVER:-"stboot.9esec.dev"}
prov_server_user=${ST_SSH_UPLOAD_USER:-"provisioner"}
prov_server_path=${ST_SSH_UPLOAD_PATH:-"/home/provisioner/www"}

[ -z "$prov_server" ] && { echo -e "upload $failed : prov_server not set in $(realpath --relative-to=${root} ${config})"; exit 1; }
[ -z "$prov_server_user" ] && { echo -e "upload $failed : prov_server_user not set in $(realpath --relative-to=${root} ${config})"; exit 1; }
[ -z "$prov_server_path" ] && { echo -e " upload $failed : prov_server_path not set in $(realpath --relative-to=${root} ${config})"; exit 1; }



bootball=""
if [[ $# -eq 0 ]] ; then
    echo "Path to a stboot.ball file must be provided"
    exit 1
else
    bootball="${1}"
    [ -f "${bootball}" ] || { echo "${bootball} does not exist";  exit 1; }
fi

echo "[INFO]: upload ${bootball} to ${prov_server_path} at ${prov_server}"
scp "$bootball" "${prov_server_user}@${prov_server}:${prov_server_path}/$(basename "${bootball}")" || { echo -e "upload via scp $failed"; exit 1; }
echo "[INFO]: successfully uploaded bootball"

