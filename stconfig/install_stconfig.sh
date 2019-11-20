#!/bin/bash 

failed="\e[1;5;31mfailed\e[0m"
BASE=$(dirname "$0")
ABS=$PWD
echo "[UROOT tooling]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT tooling] status"
git checkout --quiet stboot
git status
echo "[UROOT tooling] go install"
GOPATH=$HOME/go go install $HOME/go/src/github.com/u-root/u-root/tools/stconfig || { echo -e "installing stconfig tool $failed"; exit 1; }
echo "[UROOT tooling] install example files "
cd $ABS
if [ ! -d $BASE/../configs/ ]; then
    mkdir  $BASE/../configs/
fi
