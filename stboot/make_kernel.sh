#! /bin/bash

# USAGE
# ./make_kernel.sh <kernel_config_file> <kernel_output_file_name> <kernel_src> <kernel_ver>

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# Config variables and arguments

kernel_config_file=$1
kernel_config_file_modified="${kernel_config_file}.modified"

kernel_output_file_name=$2
kernel_output_file_backup="${kernel_output_file_name}.backup"

kernel_src=$3
kernel_ver=$4

kernel_src_tarball="${kernel_src}/${kernel_ver}.tar.xz"
kernel_src_signature="${kernel_src}/${kernel_ver}.tar.sign"

# ---

# Dev keys for verification process

src_cache="${root}/cache/kernel"
build_src=$(mktemp -d -t stmnt-XXXXXXXX)
dev_keys="torvalds@kernel.org gregkh@kernel.org"
keyring=${src_cache}/gnupg/keyring.gpg

# ---

# Copy initramfs to build directory

cp "${dir}/initramfs-linuxboot.cpio.gz" "${build_src}/initramfs-linuxboot.cpio.gz"

# ---

# Kernel build setup

if [ -f "${kernel_output_file_name}" ]; then
    while true; do
        echo "Current Linuxboot kernel:"
        ls -l "$(realpath --relative-to=${root} ${kernel_output_file_name})"
        read -rp "Rebuild kernel? (y/n)" yn
        case $yn in
          [Yy]* ) echo "[INFO]: backup existing kernel to $(realpath --relative-to=${root} ${kernel_output_file_backup})"; mv "${kernel_output_file_name}" "${kernel_output_file_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
        esac
    done
fi

if [ -f "${src_cache}/${kernel_ver}.tar.xz" ]; then
    echo "[INFO]: Using cached sources in $(realpath --relative-to=${root} ${src_cache})"
else
    echo "[INFO]: Downloading Linux Kernel source files"
    wget "${kernel_src_tarball}" -P "${src_cache}"
fi

if [ -f "${src_cache}/${kernel_ver}.tar.sign" ]; then
    echo "[INFO]: Using cached signature in $(realpath --relative-to=${root} ${src_cache})"
else
    echo "[INFO]: Downloading Linux Kernel source signature"
    wget "${kernel_src_signature}" -P "${src_cache}"
fi

[ -d "${src_cache}/gnupg" ] || { mkdir "${src_cache}/gnupg"; chmod 700 "${src_cache}/gnupg"; }

if [ -f "${keyring}" ]; then
    echo "[INFO]: Using cached kernel developer keys in $(realpath --relative-to=${root} ${src_cache})"
else
    echo "[INFO]: Fetching kernel developer keys"
    if ! gpg --batch --quiet --homedir "${src_cache}/gnupg" --auto-key-locate wkd --locate-keys ${dev_keys}; then
        echo -e "Fetching keys $failed"
        exit 1
    fi
    gpg --batch --homedir "${src_cache}/gnupg" --no-default-keyring --export ${dev_keys} > "${keyring}"
fi

echo "[INFO]: Verifying signature of the kernel tarball"
count=$(xz -cd "${src_cache}/${kernel_ver}.tar.xz" \
	   | gpgv --homedir "${src_cache}/gnupg" "--keyring=${keyring}" --status-fd=1 "${src_cache}/${kernel_ver}.tar.sign" - \
           | grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)')
if [[ "${count}" -lt 2 ]]; then
    echo -e "Verifying kernel tarball $failed"
    exit 1
fi
echo
echo "[INFO]: Successfully verified kernel source tar ball"

# ---

# Build kernel in temporary directory

echo "[INFO]: Unpacking kernel source tar ball"
[ -d "${build_src}/${kernel_ver}" ] && rm -rf "${build_src}/${kernel_ver}"
tar -xf "${src_cache}/${kernel_ver}.tar.xz" -C "${build_src}"

echo "[INFO]: Build Linuxboot kernel"
[ -f "${kernel_config_file}" ]
cp "${kernel_config_file}" "${build_src}/${kernel_ver}/.config"
cd "${build_src}/${kernel_ver}"
while true; do
    echo "[INFO]: Loaded $(realpath --relative-to=${root} ${kernel_config_file}) as .config:"
    echo "[INFO]: Any config changes you make in menuconfig will be saved to:"
    echo "[INFO]: $(realpath --relative-to=${root} ${kernel_config_file_modified})"
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
cp "${build_src}/${kernel_ver}/arch/x86/boot/bzImage" "${kernel_output_file_name}"

echo ""
echo "Successfully created $(realpath --relative-to=${root} ${kernel_output_file_name}) (${kernel_ver})"

# ---