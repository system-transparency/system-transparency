#! /bin/bash 

BASEDIR="$PWD"

echo "[UROOT]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT] status"
git checkout stboot
git status
echo "[UROOT] go install"
GOPATH=$HOME/go /usr/local/go/bin/go install $HOME/go/src/github.com/u-root/u-root/
GOPATH=$HOME/go /usr/local/go/bin/go install $HOME/go/src/github.com/u-root/u-root/cmds/boot/stboot
echo "[INITRAMFS]"
echo "[INITRAMFS] create"


