#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

common="${root}/stboot-installation/common"

# TODO: build coreboot 

bash "${common}/build_host_config.sh"

bash "${dir}/build_boot_filesystem.sh"

bash "${common}/build_data_filesystem.sh"

bash "${dir}/build_image.sh"

echo ""
echo "[INFO]: Creation of coreboot-rom not automated yet."
echo "[INFO]: Plese follow the steps in stboot-installation/coreboot-payload/README.md"

trap - EXIT