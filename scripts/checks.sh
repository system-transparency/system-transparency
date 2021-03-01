#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

misc_cmds=( "git"  "hg" "docker" "gpg" "gpgv" "qemu-system-x86_64" "id" \
            "wget" "dd" "mmd" "mcopy" "mkfs.vfat" "mkfs.ext4" "e2mkdir" "e2ls" "e2cp" "parted" \
            "mkfs" "mount" "umount" "shasum" "ssh" "scp" "tree" "truncate" \
            "bison" "flex" "pkg-config" "bc" "date" "jq" "realpath" "make" "mkfs.vfat" "sort" \
            "ssh-keygen" "hexdump")

misc_libs=( "libelf" "libcrypto" "ostree-1" )

function checkMISC {
    needs_exit=false

    for i in "${misc_cmds[@]}"
    do
        PATH=/sbin:/usr/sbin:$PATH command -v "$i" >/dev/null 2>&1 || {
            echo >&2 "$i required";
            needs_exit=true
        }
    done

    for i in "${misc_libs[@]}"
    do
    pkg-config "$i" >/dev/null 2>&1 || {
        echo >&2 "$i required";
        needs_exit=true
    }
    done

    if [[ ! -f "/lib/ld-linux.so.2" ]]
    then
        echo "i386 libc required";
        needs_exit=true
    fi

    if $needs_exit ; then
        echo 'Please install all missing dependencies!';
        exit 1;
    fi

    echo "Miscellaneous tools and dependencies OK"
}

function checkGCC {
   #maxver="9"

   command -v gcc >/dev/null 2>&1 || {
      echo >&2 "GCC required";
      exit 1;
   }

   #currentver="$(gcc -dumpversion | cut -d . -f 1)"

   #if [ "$currentver" -gt "$maxver" ]; then
   #      echo "GCC version ${currentver} is not supported. Needs version ${maxver} or earlier."
   #      echo "Hint: If you've got multiple versions of GCC installed, update-alternatives(1) might "
   #      echo "help with configuring which one should be invoked when issuing the gcc command."
   #      exit 1
   #else
   #    echo "GCC supported"
   #fi
}

function checkGO {
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
   else
       echo "GO supported"
   fi
}

function checkDebootstrap {
    if findmnt -T "${root}" | grep -cq "nodev"; then
        echo "The directory ${root} is mounted with the nodev option but debootstrap needs mknod to work."
        exit 1
    fi
    echo "Filesystem for debootstrap OK"
}

function checkSwtpmSetup {
   command -v swtpm_setup >/dev/null 2>&1 || {
      echo >&2 "swtpm_setup required";
      exit 1;
   }

   echo "swtpm_setup supported"
}

function checkSwtpm {
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
   else
       echo "swtpm 0.2.0 supported"
   fi
}

ovmf_locs=( "/usr/share/OVMF/OVMF_CODE.fd" \
            "/usr/share/edk2/ovmf/OVMF_CODE.fd" )

function checkOVMF {

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


function checkKVM {
   if [[ -c /dev/kvm ]]; then
     echo "/dev/kvm device available"
     if [[ -w /dev/kvm ]]; then
       echo "/dev/kvm is accessible by the user"
     else
       echo "user has no permissions to access /dev/kvm. add user \"`whoami`\" to the \"kvm\" group"
     fi
   else
     echo -e "/dev/kvm device not available:\n*** Please enable (nested) virtualisation on you host"
   fi
}

function run_full_check {
   echo ""
   echo "Checking dependencies ..."
   checkGCC
   checkGO
   checkMISC

   echo ""
   echo "Checking environment ..."
   checkDebootstrap
   checkSwtpmSetup
   checkSwtpm
   checkOVMF
   checkKVM
}

# run all checks if script is not sourced
[[ "$_" != "$0" ]] && run_full_check
