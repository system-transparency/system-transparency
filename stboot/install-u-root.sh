#! /bin/bash 

failed="\e[1;5;31mfailed\e[0m"
echo "[UROOT]"
cd $HOME/go/src/github.com/u-root/u-root
#echo "[UROOT] status"
git checkout --quiet stboot
git status
echo "[UROOT] go install"
GOPATH=$HOME/go go install $HOME/go/src/github.com/u-root/u-root/ || { echo -e "installing u-root $failed"; exit 1; }
#the following needs to be done as long as stboot is not merged into u-root master
GOPATH=$HOME/go go install $HOME/go/src/github.com/u-root/u-root/cmds/boot/stboot || { echo -e "installing u-root stboot patch $failed"; exit 1; }

# get the stboot uinit script from stystem transparency repository
GOPATH=$HOME/go go get -u github.com/system-transparency/uinit || { echo -e "installing stboot uinit script $failed"; exit 1; }


