#!/bin/bash 

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


lnxbt_kernel="${dir}/vmlinuz-linuxboot"
lnxbt_kernel_backup="${dir}/vmlinuz-linuxboot.backup"
kernel_src="https://cdn.kernel.org/pub/linux/kernel/v4.x/"
kernel_ver="linux-4.19.6"
kernel_config="${dir}/x86_64_x11ssh_qemu_linuxboot.defconfig"
tmp=$(mktemp -d -t stkernel-XXXXXXXX)
dev_keys="torvalds@kernel.org gregkh@kernel.org"

if [ -f "${lnxbt_kernel}" ]; then
    while true; do
       echo "Current Linuxboot kernel:"
       ls -l "${lnxbt_kernel}"
       echo "kernel config:"
       ls -l "${kernel_config}"
       read -rp "Recompile? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing kernel to ${lnxbt_kernel_backup}"; mv "${lnxbt_kernel}" "${lnxbt_kernel_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi


echo "[INFO]: Downloading Linux Kernel source files and signature"
wget "${kernel_src}/${kernel_ver}.tar.xz" -P "${tmp}" || { rm -rf "${tmp}"; echo -e "Downloading source files $failed"; exit 1; }
wget "${kernel_src}/${kernel_ver}.tar.sign" -P "${tmp}" || { rm -rf "${tmp}"; echo -e "Downloading signature $failed"; exit 1; }

mkdir "${tmp}/gnupg"
echo "[INFO]: Fetching kernel developer keys"
if ! gpg --batch --quiet --homedir "${tmp}/gnupg" --auto-key-locate wkd --locate-keys ${dev_keys}; then
    echo -e "Fetching keys $failed"
    rm -rf "${tmp}"
    exit 1
fi
keyring=${tmp}/gnupg/keyring.gpg
gpg --batch --homedir "${tmp}/gnupg" --no-default-keyring --export ${dev_keys} > "${keyring}"

echo "[INFO]: Verifying signature of the kernel tarball"
count=$(xz -cd "${tmp}/${kernel_ver}.tar.xz" \
        | gpgv --homedir "${tmp}/gnupg" "--keyring=${keyring}" --status-fd=1 "${tmp}/${kernel_ver}.tar.sign" - \
        | grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)')
if [[ "${count}" -lt 2 ]]; then
    echo -e "Verifying kernel tarball $failed"
    rm -rf "${tmp}"
    exit 1
fi

echo
echo "[INFO]: Successfully downloaded and verified kernel"
echo "[INFO]: Build Linuxboot kernel"

tar -xf "${tmp}/${kernel_ver}.tar.xz" -C "${tmp}" || { rm -rf "${tmp}"; echo -e "Unpacking $failed"; exit 1; }

[ -f "${kernel_config}" ] || { rm -rf "${tmp}"; echo -e "Finding $kernel_config $failed"; exit 1; }
cp -v "${kernel_config}" "${tmp}/${kernel_ver}/.config"
cd "${tmp}/${kernel_ver}"
while true; do
    echo "Following desconfig will be used:" 
    ls -l "${kernel_config}"
    echo "It is recommended to just save&exit in the upcoming menu."
    read -rp "Press any key to continue" x
    case $x in
       * ) break;;
    esac
done 
make menuconfig
make "-j$(nproc)" || { rm -rf "${tmp}"; echo -e "Compiling kernel $failed"; exit 1; }
cd "${dir}"
cp -v "${tmp}/${kernel_ver}/arch/x86/boot/bzImage" "$lnxbt_kernel"
rm -rf "${tmp}"
echo
echo "Successfully created $lnxbt_kernel ($kernel_ver)"

