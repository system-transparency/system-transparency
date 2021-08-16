#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

# commands dependencies
declare -a deps_cmds
# dpkg dependencies
declare -a deps_dpkg
# pkgconf build dependencies
declare -a deps_pkgconf


### XXX: find a better way to organise dependencies
### core
deps_cmds+=(wget)
deps_dpkg+=(wget)
deps_cmds+=(git)
deps_dpkg+=(git)
deps_cmds+=(gcc)
deps_dpkg+=(gcc)
deps_cmds+=(bc)
deps_dpkg+=(bc)
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
# XXX: add zlib dpkg
deps_pkgconf+=(zlib)
# XXX: add libcrypto dpkg
deps_pkgconf+=(libcrypto)
### tboot
deps_cmds+=(hg)
deps_dpkg+=(mercurial)
deps_dpkg+=(trousers)
### stboot installation
deps_cmds+=(jq)
deps_dpkg+=(jq)
deps_cmds+=(e2mkdir)
deps_dpkg+=(e2tools)
deps_cmds+=(mcopy)
deps_dpkg+=(mtools)
### syslinux
deps_dpkg+=(libc6-i386)
### qemu run
deps_cmds+=(qemu-system-x86_64)
deps_dpkg+=(qemu-kvm)

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

check_functions+=(check_MISC)
function check_MISC {
    tmp_out=$(mktemp)
    trap "rm $tmp_out" EXIT
    printf "#include <trousers/tss.h>\n" | gcc -x c - -Wl,--defsym=main=0 -o $tmp_out >/dev/null 2>&1 || echo "libtspi-dev/trousers-devel package is required"
}

check_functions+=(check_GO)
function check_GO {
   minver=("1" "13")

   command -v go >/dev/null 2>&1 || {
      echo >&2 "GO required";
      exit 1;
   }

   ver=$(go version | cut -d ' ' -f 3 | sed 's/go//')
   majorver="$(echo $ver | cut -d . -f 1)"
   minorver="$(echo $ver | cut -d . -f 2)"

   if [ "$majorver" -le "${minver[0]}" ] && [ "$minorver" -lt "${minver[1]}" ]; then
         echo "GO version ${majorver}.${minorver} is not supported. Needs version ${minver[0]}.${minver[1]} or later."
         exit 1
   fi
}


check_functions+=(check_swtpm)
function check_swtpm {
   minver=("0" "2")

   command -v swtpm >/dev/null 2>&1 || {
      echo >&2 "swtpm required";
      exit 1;
   }

   ver=$(swtpm --version | cut -d ' ' -f 4 | sed 's/,//')
   majorver="$(echo $ver | cut -d . -f 1)"
   minorver="$(echo $ver | cut -d . -f 2)"

   if [ "$majorver" -le "${minver[0]}" ] && [ "$minorver" -lt "${minver[1]}" ]; then
         echo "swtpm version ${majorver}.${minorver} is not supported. Needs version ${minver[0]}.${minver[1]} or later."
         exit 1
   fi
}

ovmf_locs=( "/usr/share/OVMF/OVMF_CODE.fd" \
            "/usr/share/edk2/ovmf/OVMF_CODE.fd" )

check_functions+=(check_OVMF)
function check_OVMF {

    found=0
    for i in "${ovmf_locs[@]}"
    do
        if [ -f "$i" ]; then
          found=1
        fi
    done
   if [ "$found" -gt 0 ]; then
     echo "OVMF found"
   else
     echo "OVMF not found found"
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
