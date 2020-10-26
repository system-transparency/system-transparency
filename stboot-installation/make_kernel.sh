#! /bin/bash

# USAGE
# ./make_kernel.sh <kernel_config_file> <kernel_output_file_name> <kernel_src> <kernel_ver>

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# Config variables and arguments

kernel_config_file=$1

kernel_output_file=$2
kernel_output_file_backup="${kernel_output_file}.backup"

kernel_version=$3


# ---

# Kernel build setup

if [ -f "${kernel_output_file}" ]; then
    while true; do
        echo "Current Linuxboot kernel:"
        ls -l "$(realpath --relative-to="${root}" "${kernel_output_file}")"
        read -rp "Rebuild kernel? (y/n)" yn
        case $yn in
          [Yy]* ) echo "[INFO]: backup existing kernel to $(realpath --relative-to="${root}" "${kernel_output_file_backup}")"; mv "${kernel_output_file}" "${kernel_output_file_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
        esac
    done
fi

bash "${dir}/build_kernel.sh" "${kernel_config_file}" "${kernel_output_file}" "${kernel_version}"


