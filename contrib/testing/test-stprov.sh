#! /bin/sh
set -eu
set -x

n="$1"; shift
stprov=stprov-${n}.iso
stboot=stboot-${n}.iso

./build-ospkg.sh
./build-stprov.sh
scp out/stprov.iso "tee.sigsum.org:/var/lib/sambashares/iso/${stprov}"

echo "Mount ISO $stprov in BMC and restart server"
read -r

./build-stboot.sh
scp out/stboot.iso "tee.sigsum.org:/var/lib/sambashares/iso/${stboot}"
scp out/ospkgs/os-pkg-example-ubuntu20.* tee.sigsum.org:/var/www/netboot/

echo "Mount ISO $stboot in BMC and restart server"
read -r
