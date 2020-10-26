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
kernel_config_file_modified="${kernel_config_file}.modified"
kernel_output_file=$2
kernel_output_file_backup="${kernel_output_file}.backup"
kernel_version=$3
major=$(echo "${kernel_version}" | head -c1)
kernel_src="https://cdn.kernel.org/pub/linux/kernel/v${major}.x"
kernel_name="linux-${kernel_version}"
kernel_tarball="${kernel_src}/${kernel_name}.tar.xz"
kernel_signature="${kernel_src}/${kernel_name}.tar.sign"
kernel_cache="${root}/cache/kernel"

dev_key_1="torvalds@kernel.org"
dev_key_2="gregkh@kernel.org"
keyring=${kernel_cache}/gnupg/keyring.gpg

if [ -f "${kernel_output_file}" ]; then
    echo
    echo "[INFO]: backup existing kernel to $(realpath --relative-to="${root}" "${kernel_output_file_backup}")"
    mv "${kernel_output_file}" "${kernel_output_file_backup}"
fi

if [ -d "${kernel_cache}/${kernel_name}" ]; then
    echo
    echo "[INFO]: Using cached sources in $(realpath --relative-to="${root}" "${kernel_cache}/${kernel_name}")"
else
    # sources
    echo "[INFO]: Downloading Linux Kernel source files from ${kernel_cache}/${kernel_name}"
    rm -f "${kernel_tarball}"
    wget "${kernel_tarball}" -P "${kernel_cache}"
    # signature
    if [ -f "${kernel_cache}/${kernel_name}.tar.sign" ]; then
        echo "[INFO]: Using cached signature in $(realpath --relative-to="${root}" "${kernel_cache}/${kernel_name}.tar.sign")"
    else
        echo "[INFO]: Downloading Linux Kernel source signature"
        wget "${kernel_signature}" -P "${kernel_cache}"
    fi
    # developer keys
    [ -d "${kernel_cache}/gnupg" ] || { mkdir "${kernel_cache}/gnupg"; chmod 700 "${kernel_cache}/gnupg"; }
    if [ -f "${keyring}" ]; then
        echo "[INFO]: Using cached kernel developer keys in $(realpath --relative-to="${root}" "${keyring}")"
    else
        echo "[INFO]: Fetching kernel developer keys"
    if ! gpg -v --batch --homedir "${kernel_cache}/gnupg" --auto-key-locate wkd --locate-keys ${dev_key_1} ${dev_key_2}; then
        exit 1
    fi
        gpg --batch --homedir "${kernel_cache}/gnupg" --no-default-keyring --export ${dev_key_1} ${dev_key_2} > "${keyring}"
    fi
    # verification
    echo "[INFO]: Verifying signature of the kernel tarball"
    count=$(xz -cd "${kernel_cache}/${kernel_name}.tar.xz" \
	    | gpgv --homedir "${kernel_cache}/gnupg" "--keyring=${keyring}" --status-fd=1 "${kernel_cache}/${kernel_name}.tar.sign" - \
        | grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)')
    if [[ "${count}" -lt 2 ]]; then
        rm -rf "${kernel_cache:?b}/${kernel_name}" "${kernel_tarball}"
        exit 1
    fi
    echo
    echo "[INFO]: Successfully verified kernel sources"
    echo "[INFO]: Unpacking kernel source tarball"
    [ -d "${kernel_cache}/${kernel_name}" ] && rm -rf "${kernel_cache:?}/${kernel_name:?}"
    tar -xf "${kernel_cache}/${kernel_name}.tar.xz" -C "${kernel_cache}"
fi

# Build kernel in cache
echo "[INFO]: Building Linuxboot kernel"
if [ -f "${kernel_config_file}.patch" ]; then
    cfg=${kernel_config_file}.patch
elif [ -f "${kernel_config_file}" ]; then
    cfg=${kernel_config_file}
fi

cp "${cfg}" "${kernel_cache}/${kernel_name}/.config"
cd "${kernel_cache}/${kernel_name}"
while true; do
    echo
    echo "[INFO]: Loaded $(realpath --relative-to="${root}" "${cfg}") as .config:"
    echo "[INFO]: Any config changes you make in menuconfig will be saved to:"
    echo "[INFO]: $(realpath --relative-to="${root}" "${kernel_config_file_modified}")"
    echo "[INFO]: However, it is recommended to just save and exit without modifications."
    read -rp "Press any key to continue" x
    case $x in
        * ) break;;
    esac
done

make menuconfig
make savedefconfig
cp defconfig "${kernel_config_file_modified}"

make "-j$(nproc)"
cd "${dir}"
cp "${kernel_cache}/${kernel_name}/arch/x86/boot/bzImage" "${kernel_output_file}"

echo ""
echo "Successfully created $(realpath --relative-to="${root}" "${kernel_output_file}") (${kernel_name})"


