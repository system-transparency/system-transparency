#! /bin/bash 

BASEDIR="$PWD"

cd $BASEDIR

# minimum
#GOPATH=$HOME/go $HOME/go/bin/u-root -build=bb -o linuxboot/initramfs_uroot.cpio \
#github.com/u-root/u-root/cmds/core/init \
#github.com/u-root/u-root/cmds/core/elvish \
#github.com/u-root/u-root/cmds/core/ip \
#github.com/u-root/u-root/cmds/core/wget \
#github.com/u-root/u-root/cmds/boot/stboot 

#develop
GOPATH=$HOME/go $HOME/go/bin/u-root -build=bb -o linuxboot/initramfs_uroot.cpio \
-files "$BASEDIR/include/DST_Root_CA_X3.pem:root/DST_Root_CA_X3.pem" \
-files "$BASEDIR/include/LetsEncrypt_Authority_X3_signed_by_X1.pem:root/LetsEncrypt_Authority_X3.pem" \
-files "$BASEDIR/include/netsetup.elv:root/netsetup.elv" \
all

