#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

common="${root}/operating-system/common"

bash "${common}/build_tboot.sh"

bash "${common}/get_acms.sh"

bash "${dir}/build_os_artefacts.sh"

trap - EXIT
