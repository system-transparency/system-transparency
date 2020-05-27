#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace


# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

echo
echo "[INFO]: Dummy script. Work in progress: Run QEMU with coreboot ROM."
exit 1