#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# commands dependencies
declare -a deps_cmds
# dpkg dependencies
declare -a deps_dpkg
# pkgconf build dependencies
declare -a deps_pkgconf


### XXX: find a better way to organise dependencies
### core
deps_cmds+=(curl)
deps_dpkg+=(curl)
deps_cmds+=(xz)
deps_dpkg+=(xz-utils)
deps_cmds+=(git)
deps_dpkg+=(git)
deps_cmds+=(gcc)
deps_dpkg+=(gcc)
deps_cmds+=(make)
deps_dpkg+=(make)
deps_cmds+=(bc)
deps_dpkg+=(bc)
deps_cmds+=(go)
deps_dpkg+=(golang)
deps_cmds+=(mkfs.vfat)
deps_dpkg+=(dosfstools)
deps_cmds+=(udevadm)
deps_dpkg+=(udev)
### linux kernel
deps_cmds+=(flex)
deps_dpkg+=(flex)
deps_cmds+=(bison)
deps_dpkg+=(bison)
deps_cmds+=(pkg-config)
deps_dpkg+=(pkg-config)
deps_pkgconf+=(libelf)
deps_dpkg+=(libelf-dev)
deps_cmds+=(gpg)
deps_dpkg+=(gpg)
deps_cmds+=(jq)
deps_dpkg+=(jq)
deps_cmds+=(e2mkdir)
deps_dpkg+=(e2tools)
deps_cmds+=(mmd)
deps_cmds+=(mcopy)
deps_dpkg+=(mtools)
deps_cmds+=(parted)
deps_dpkg+=(parted)
### syslinux
deps_dpkg+=(libc6-i386)

declare -a check_functions

check_functions+=(check_cmds)
function check_cmds {
    for i in "${deps_cmds[@]}"
    do
        PATH=/sbin:/usr/sbin:$PATH command -v "$i" >/dev/null 2>&1 || {
            echo >&2 "$i required";
        }
    done
}

check_functions+=(check_pkgconf)
function check_pkgconf {
    for i in "${deps_pkgconf[@]}"
    do
    pkg-config "$i" >/dev/null 2>&1 || {
        echo >&2 "$i required";
    }
    done
}

check_functions+=(check_i386_libc)
function check_i386_libc {
    if [[ ! -f "/lib/ld-linux.so.2" ]]
    then
        echo "i386 libc required";
    fi
}

check_functions+=(check_GO)
function check_GO {
   minver=("1" "13")

   command -v go >/dev/null 2>&1 || {
      echo >&2 "Go required";
      return 1
   }

   ver=$(go version | cut -d ' ' -f 3 | sed 's/go//')
   majorver="$(echo $ver | cut -d . -f 1)"
   minorver="$(echo $ver | cut -d . -f 2)"

   if [ "$majorver" -le "${minver[0]}" ] && [ "$minorver" -lt "${minver[1]}" ]; then
         echo "GO version ${majorver}.${minorver} is not supported. Needs version ${minver[0]}.${minver[1]} or later."
   else
         deps_dpkg+=(golang)
   fi
}

function check {
    for check in "${check_functions[@]}"; do
        ${check}
    done
}

function install {
    SUDO=
    if [ "$(id -u)" -ne 0 ];
    then
        if sudo -v
        then
            SUDO="sudo"
        else
            >&2 echo Please run as root
            exit 1
        fi
    fi
    export DEBIAN_FRONTEND="noninteractive"
    $SUDO apt-get update -yq && $SUDO apt-get install -yq "${deps_dpkg[@]}"
}

if [[ "$#" -eq 0 ]]
then
    check
    exit 0
fi

case "$1" in
    install)
        install
        ;;
    check)
        check
        ;;
    *)
        >&2 echo "Unknown command: \"$1\""
        ;;
esac
