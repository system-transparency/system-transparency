#!/bin/bash 

# make stconfig/configs folder (gitignore) and copy test files into it
BASE=$(dirname "$0")
ABS=$PWD
echo "[UROOT tools]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT tools] status"
git checkout stboot
git status
echo "[UROOT tools] go install"
GOPATH=$HOME/go /usr/bin/go install $HOME/go/src/github.com/u-root/u-root/tools/stconfig
echo "[UROOT installed]"
echo "[Copying files]"
cd $ABS
echo "$BASE"
mkdir $BASE/../configs
mkdir $BASE/../configs/example
mkdir $BASE/../configs/example/signing
mkdir $BASE/../configs/example/initrds
cp -r -v $BASE/../testitems/kernels $BASE/../configs/example/kernels
cp -v $BASE/../testitems/signing/create-keys.sh $BASE/../configs/example/signing/create-keys.sh
cp -v $BASE/../testitems/manifest.json $BASE/../configs/example/manifest.json
echo "No Initramfs available at the time."
#cp $BASE/../testitems/initramfs $BASE/../configs/example/initramfs