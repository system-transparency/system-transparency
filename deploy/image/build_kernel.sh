#!/bin/bash 

failed="\e[1;5;31mfailed\e[0m"
BASE=$(dirname "$0")

LNXBT_KERNEL="$BASE/vmlinuz-linuxboot"
KERNEL_SRC="https://cdn.kernel.org/pub/linux/kernel/v4.x/"
KERNEL_VER="linux-4.19.6"
KERNEL_CONFIG="$BASE/x86_64_linuxboot_config"
TMP=$(mktemp -d -t stkernel-XXXXXXXX)
DEVKEYS="torvalds@kernel.org gregkh@kernel.org"

if [ -f "$LNXBT_KERNEL" ]; then
    while true; do
       read -p "$LNXBT_KERNEL already exists! Override? (y/n)" yn
       case $yn in
          [Yy]* ) rm $IMG; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
       esac
    done 
fi

echo "____ Downloading Linux Kernel source files and signature____"
wget $KERNEL_SRC/${KERNEL_VER}.tar.xz -P $TMP || { rm -rf ${TMP}; echo -e "Downloading source files $failed"; exit 1; }
#xz -d -v $TMP/${KERNEL_VER}.tar.xz || { echo -e "Decompression $failed"; exit 1; }
wget $KERNEL_SRC/${KERNEL_VER}.tar.sign -P $TMP || { rm -rf ${TMP}; echo -e "Downloading signature $failed"; exit 1; }

mkdir ${TMP}/gnupg
echo "____ Fetching all the necessary keys ____"
gpg --batch --quiet \
    --homedir ${TMP}/gnupg \
    --auto-key-locate wkd \
    --locate-keys ${DEVKEYS} 
if [[ $? != "0" ]]; then
    echo -e "Fetching keys $failed"
    rm -rf ${TMP}
    exit 1
fi
KEYRING=${TMP}/gnupg/keyring.gpg
gpg --batch --export ${DEVKEYS} > ${KEYRING}
DEVKEYRING=${TMP}/gnupg/devkeyring.gpg}

echo "____ Verifying signature on the kernel tarball ____"
COUNT=$(xz -cd ${TMP}/${KERNEL_VER}.tar.xz \
        | gpgv --keyring=${KEYRING} --status-fd=1 ${TMP}/${KERNEL_VER}.tar.sign - \
        | grep -c -E '^\[GNUPG:\] (GOODSIG|VALIDSIG)')
if [[ ${COUNT} -lt 2 ]]; then
    echo -e "Verifying kernle tarball $failed"
    rm -rf ${TMP}
    exit 1
fi

echo
echo "Successfully downloaded and verified kernel"

tar -xf ${TMP}/${KERNEL_VER}.tar.xz -C $TMP || { rm -rf ${TMP}; echo -e "Unpacking $failed"; exit 1; }

[ -f "$KERNEL_CONFIG" ] || { rm -rf ${TMP}; echo -e "Finding $KERNEL_CONFIG $failed"; exit 1; }
cp -v $KERNEL_CONFIG ${TMP}/${KERNEL_VER}/.config
SAVEDIR=$(pwd)
cd ${TMP}/${KERNEL_VER}
make -j$(nproc) || { rm -rf ${TMP}; echo -e "Compiling kernel $failed"; exit 1; }
cd $SAVEDIR
cp -v ${TMP}/${KERNEL_VER}/arch/x86/boot/bzImage $LNXBT_KERNEL
rm -rf ${TMP}
echo
echo "Successfully created $LNXBT_KERNEL ($KERNEL_VER)"

