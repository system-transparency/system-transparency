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
tmp=${ST_STKERNEL_TMPDIR:-$(mktemp -d -t stkernel-XXXXXXXX)}
dev_keys="torvalds@kernel.org gregkh@kernel.org"

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


echo "[INFO]: Downloading Linux Kernel source files and signature"
[ -f "${tmp}/${kernel_ver}.tar.xz" ] || wget "${kernel_src}/${kernel_ver}.tar.xz" -P "${tmp}" || { rm -rf "${tmp}"; echo -e "Downloading source files $failed"; exit 1; }
[ -f "${tmp}/${kernel_ver}.tar.sign" ] || wget "${kernel_src}/${kernel_ver}.tar.sign" -P "${tmp}" || { rm -rf "${tmp}"; echo -e "Downloading signature $failed"; exit 1; }

[ -d "${tmp}/gnupg" ] || mkdir "${tmp}/gnupg"
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
cp "${kernel_config}" "${tmp}/${kernel_ver}/.config"
cd "${tmp}/${kernel_ver}"
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
make "-j$(nproc)" || { rm -rf "${tmp}"; echo -e "Compiling kernel $failed"; exit 1; }
cd "${dir}"
cp "${tmp}/${kernel_ver}/arch/x86/boot/bzImage" "$lnxbt_kernel"
rm -rf "${tmp}"

echo ""
chown -c "${user_name}" "${lnxbt_kernel}"
chown -c "${user_name}" "${lnxbt_kernel_backup}"
chown -c "${user_name}" "${kernel_config}"
chown -c "${user_name}" "${kernel_config_mod}"

echo ""
echo "Successfully created $(realpath --relative-to=${root} $lnxbt_kernel) ($kernel_ver)"
echo "Any config changes you may have made via menuconfig are saved to:"
echo "$(realpath --relative-to=${root} ${kernel_config_mod})"

