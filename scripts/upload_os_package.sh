#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

source ${root}/run.config

failed="\e[1;5;31mfailed\e[0m"

prov_server=${ST_SSH_UPLOAD_SERVER}
prov_server_user=${ST_SSH_UPLOAD_USER}
prov_server_path=${ST_SSH_UPLOAD_PATH}

[ -z "$prov_server" ] && { echo -e "upload $failed : prov_server not set in run.config"; exit 1; }
[ -z "$prov_server_user" ] && { echo -e "upload $failed : prov_server_user not set in run.config"; exit 1; }
[ -z "$prov_server_path" ] && { echo -e " upload $failed : prov_server_path not set in run.config"; exit 1; }

os_package=""
if [[ $# -eq 0 ]] ; then
    echo "Path to a OS package zip file must be provided"
    exit 1
else
    os_package="${1}"
    [ -f "${os_package}" ] || { echo "${os_package} does not exist";  exit 1; }
fi

echo "[INFO]: upload $(realpath --relative-to="${root}" "${os_package}") to ${prov_server_path}/ospkg.zip at ${prov_server}"
scp "$os_package" "${prov_server_user}@${prov_server}:${prov_server_path}/ospkg.zip" || { echo -e "upload via scp $failed"; exit 1; }
echo "[INFO]: successfully uploaded OS package"

