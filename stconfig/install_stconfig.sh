#!/bin/bash 

# make stconfig/configs folder (gitignore) and copy test files into it
BASE=$(dirname "$0")
ABS=$PWD
echo "[UROOT tooling]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT tooling] status"
git checkout --quiet stboot
git status
echo "[UROOT tooling] go install"
GOPATH=$HOME/go go install $HOME/go/src/github.com/u-root/u-root/tools/stconfig
echo "[UROOT tooling] install example files "
cd $ABS
if [ -d $BASE/../configs/example ]; then
    rmdir -v --ignore-fail-on-non-empty $BASE/../configs/example
fi
mkdir -p $BASE/../configs/example/kernels
mkdir -p $BASE/../configs/example/initrds
mkdir -p $BASE/../configs/example/signing
cp -r -v $BASE/../testitems/kernels/* $BASE/../configs/example/kernels
cp -r -v $BASE/../testitems/signing/* $BASE/../configs/example/signing
cp -v $BASE/../testitems/manifest.json $BASE/../configs/example/manifest.json
