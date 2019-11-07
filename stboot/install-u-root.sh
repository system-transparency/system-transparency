#! /bin/bash 

echo "[UROOT]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT] status"
git checkout --quiet stboot
git status
echo "[UROOT] go install"
GOPATH=$HOME/go go install $HOME/go/src/github.com/u-root/u-root/
GOPATH=$HOME/go go install $HOME/go/src/github.com/u-root/u-root/cmds/boot/stboot



