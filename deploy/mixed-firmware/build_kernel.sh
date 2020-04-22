#!/bin/bash 

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

failed="\e[1;5;31mfailed\e[0m"

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"


lnxbt_kernel="${dir}/vmlinuz-linuxboot"
lnxbt_kernel_backup="${dir}/vmlinuz-linuxboot.backup"
kernel_src="https://cdn.kernel.org/pub/linux/kernel/v4.x/"
kernel_ver="linux-4.19.6"
kernel_config="${dir}/x86_64_x11ssh_qemu_linuxboot.defconfig"
kernel_config_mod="${dir}/x86_64_x11ssh_qemu_linuxboot.defconfig.modified"
src="${root}/src/kernel"
dev_keys="torvalds@kernel.org gregkh@kernel.org"
keyring=${src}/gnupg/keyring.gpg

user_name="$1"

if ! id "${user_name}" >/dev/null 2>&1
then
   echo "User ${user_name} does not exist"
   exit 1
fi

if [ -f "${lnxbt_kernel}" ]; then
    while true; do
       echo "Current Linuxboot kernel:"
       ls -l "$(realpath --relative-to=${root} ${lnxbt_kernel})"
       read -rp "Recompile? (y/n)" yn
       case $yn in
          [Yy]* ) echo "[INFO]: backup existing kernel to $(realpath --relative-to=${root} ${lnxbt_kernel_backup})"; mv "${lnxbt_kernel}" "${lnxbt_kernel_backup}"; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

if [ -f "${src}/${kernel_ver}.tar.xz" ]; then
    echo "[INFO]: Using cached sources in $(realpath --relative-to=${root} ${src})"
else
    echo "[INFO]: Downloading Linux Kernel source files"
    wget "${kernel_src}/${kernel_ver}.tar.xz" -P "${src}" || { echo -e "Downloading source files $failed"; exit 1; }
fi

if [ -f "${src}/${kernel_ver}.tar.sign" ]; then
    echo "[INFO]: Using cached signature in $(realpath --relative-to=${root} ${src})"
else
    echo "[INFO]: Downloading Linux Kernel source signature"
    wget "${kernel_src}/${kernel_ver}.tar.sign" -P "${src}" || { echo -e "Downloading signature $failed"; exit 1; }
fi

[ -d "${src}/gnupg" ] || { mkdir "${src}/gnupg"; chmod 700 "${src}/gnupg"; }

if [ -f "${keyring}" ]; then
    echo "[INFO]: Using cached kernel developer keys in $(realpath --relative-to=${root} ${src})"
else
    echo "[INFO]: Fetching kernel developer keys"
    if ! gpg --batch --quiet --homedir "${src}/gnupg" --auto-key-locate wkd --locate-keys ${dev_keys}; then
        echo -e "Fetching keys $failed"
        exit 1
    fi
    gpg --batch --homedir "${src}/gnupg" --no-default-keyring --export ${dev_keys} > "${keyring}"
fi

echo "[INFO]: Verifying signature of the kernel tarball"
count=$(xz -cd "${src}/${kernel_ver}.tar.xz" \
	   | gpgv --homedir "${src}/gnupg" "--keyring=${keyring}" --status-fd=1 "${src}/${kernel_ver}.tar.sign" - \
           | grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)')
if [[ "${count}" -lt 2 ]]; then
    echo -e "Verifying kernel tarball $failed"
    exit 1
fi
echo
echo "[INFO]: Successfully verified kernel source tar ball"

echo "[INFO]: Unpacking kernel source tar ball"
[ -d "${src}/${kernel_ver}" ] && rm -rf "${src}/${kernel_ver}"
tar -xf "${src}/${kernel_ver}.tar.xz" -C "${src}" || { echo -e "Unpacking $failed"; exit 1; }
chown -R "${user_name}" "${src}"

echo "[INFO]: Build Linuxboot kernel"
[ -f "${kernel_config}" ] || { echo -e "Finding $kernel_config $failed"; exit 1; }
cp "${kernel_config}" "${src}/${kernel_ver}/.config"
cd "${src}/${kernel_ver}"
while true; do
    echo "Load  $(realpath --relative-to=${root} ${kernel_config}) as .config:" 
    echo "It is recommended to just save&exit in the upcoming menu."
    read -rp "Press any key to continue" x
    case $x in
       * ) break;;
    esac
done 
make menuconfig
make savedefconfig 
cp defconfig "${kernel_config_mod}"

make "-j$(nproc)" || { echo -e "Compiling kernel $failed"; exit 1; }
cd "${dir}"
cp "${src}/${kernel_ver}/arch/x86/boot/bzImage" "$lnxbt_kernel"

echo ""
[ -f "${lnxbt_kernel}" ] && chown -c "${user_name}" "${lnxbt_kernel}"
[ -f "${lnxbt_kernel_backup}" ] && chown -c "${user_name}" "${lnxbt_kernel_backup}"
[ -f "${kernel_config}" ] && chown -c "${user_name}" "${kernel_config}"
[ -f "${kernel_config_mod}" ] && chown -c "${user_name}" "${kernel_config_mod}"

echo ""
echo "Successfully created $(realpath --relative-to=${root} $lnxbt_kernel) ($kernel_ver)"
echo "Any config changes you may have made via menuconfig are saved to:"
echo "$(realpath --relative-to=${root} ${kernel_config_mod})"

trap - EXIT
