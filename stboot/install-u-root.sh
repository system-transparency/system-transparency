#! /bin/bash 

BASEDIR="$PWD"
GOBIN="/usr/bin/go"

echo "[UROOT]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT] status"
git checkout stboot
git status
echo "[UROOT] go install"
GOPATH=$HOME/go $GOBIN install $HOME/go/src/github.com/u-root/u-root/
GOPATH=$HOME/go $GOBIN install $HOME/go/src/github.com/u-root/u-root/cmds/boot/stboot
echo "[UROOT installed]"



