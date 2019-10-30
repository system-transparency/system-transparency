#!/bin/bash 

# make stconfig/configs folder (gitignore) and copy test files into it
BASEDIR=$PWD
echo "[UROOT tools]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT tools] status"
git checkout stboot
git status
echo "[UROOT tools] go install"
GOPATH=$HOME/go /usr/bin/go install $HOME/go/src/github.com/u-root/u-root/tools/stconfig
echo "[UROOT installed]"
echo "[Copying files]"
cd $BASEDIR/..
mkdir configs
cd $BASEDIR/../configs
mkdir example
cp -r $BASEDIR/../testitems/kernels $BASEDIR/../configs/example/kernels
cp -r $BASEDIR/../testitems/signing $BASEDIR/../configs/example/signing
cp $BASEDIR/../testitems/manifest.json $BASEDIR/../configs/example/manifest.json
echo "No Initramfs available at the time."
#cp $BASEDIR/../testitems/initramfs $BASEDIR/../configs/example/initramfs