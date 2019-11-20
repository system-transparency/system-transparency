#!/bin/sh

BASE=$(dirname "$0")

#Check if debian directory exists, if so: delete it.
if [ -d $BASE/../../configs/debian ]; then
    rmdir -v --ignore-fail-on-non-empty $BASE/../../configs/debian
fi
#Create debian directory with subdirectories
mkdir -p $BASE/../../configs/debian/kernels
mkdir -p $BASE/../../configs/debian/initrds
mkdir -p $BASE/../../configs/debian/signing
#Copy signing keys for debian use to directory
cp -r -v $BASE/../../testitems/signing/root.cert $BASE/../../configs/debian/signing/root.cert

#Build docker image
sudo docker build -t debos .

#Build DebianOS reproducible via docker container
sudo docker run --cap-add=SYS_ADMIN --privileged -it -v $(pwd)/../../:/system-transparency/ debos


echo "                                                                 "
echo "-----------------------------------------------------------------"
echo "Kernel and Initramfs generated at: $BASE/out"
echo "-----------------------------------------------------------------"
echo "                                                                 "

#create mainfest.json inside example directory
./$BASE/../../stconfig/create_manifest.sh