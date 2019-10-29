#! /bin/bash 

BASEDIR="$PWD"

# make stconfig/configs folder (gitignore) and copy test files into it

echo "[UROOT tools]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT tools] status"
git checkout stboot
git status
echo "[UROOT tools] go install"
GOPATH=$HOME/go /usr/local/go/bin/go install $HOME/go/src/github.com/u-root/u-root/tools/stconfig
cd $BASEDIR

