#! /bin/bash 

failed="\e[1;5;31mfailed\e[0m"
BASE=$(dirname "$0")
if [ "$1" == "dev" ] ; then
    echo "### make initramfs with full tooling for development ###"
    GOPATH=$HOME/go $HOME/go/bin/u-root -build=bb -o $BASE/initramfs-linuxboot.cpio \
    -files "$BASE/include/netvars.json:netvars.json" \
    -files "$BASE/include/LetsEncrypt_Authority_X3_signed_by_X1.pem:root/LetsEncrypt_Authority_X3.pem" \
    -files "$BASE/include/netsetup.elv:root/netsetup.elv" \
    all \
    github.com/system-transparency/uinit \
    || { echo -e "creating initramfs $failed"; exit 1; }
else
    echo "### make minimal initramf including stboot only ###"
    GOPATH=$HOME/go $HOME/go/bin/u-root -build=bb -o $BASE/initramfs-linuxboot.cpio \
    -files "$BASE/include/netvars.json:netvars.json" \
    -files "$BASE/include/LetsEncrypt_Authority_X3_signed_by_X1.pem:root/LetsEncrypt_Authority_X3.pem" \
    github.com/u-root/u-root/cmds/core/init \
    github.com/u-root/u-root/cmds/core/elvish \
    github.com/u-root/u-root/cmds/core/ip \
    github.com/u-root/u-root/cmds/boot/stboot \
    github.com/system-transparency/uinit \
    || { echo -e "creating initramfs $failed"; exit 1; }
fi 


