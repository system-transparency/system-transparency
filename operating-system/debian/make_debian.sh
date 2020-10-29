#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"


bash "${root}/operating-system/build_tboot.sh"

bash "${root}/operating-system/get_acms.sh"

bash "${dir}/build_os_artefacts.sh"

trap - EXIT