#!/bin/bash

failed="\e[1;5;31mfailed\e[0m"
BASE=$(dirname "$0")
SERVER="mullvad.9esec.io"
BOOTFILE="stboot.zip"
CONFIGPATH=${1:-$BASE/../configs/example/manifest.json}

WORKDIR=$(dirname "$CONFIGPATH")
MANIFEST=$(basename "$CONFIGPATH")
echo $WORKDIR/$MANIFEST

echo "[INFO]: cleaning up"
rm -f $WORKDIR/$BOOTFILE || { echo -e "Removing old $BOOTFILE $failed"; exit 1; }
ssh -t root@$SERVER 'rm -f /var/www/testdata/bc.zip; exit' || { echo -e "Removing old $BOOTFILE on $SERVER $failed"; exit 1; }

echo "[INFO]: pack manifest.json, OS-kernel, etc. into $BOOTFILE"

stconfig create $WORKDIR/$MANIFEST -o $WORKDIR/$BOOTFILE || { echo -e "stconfig $failed"; exit 1; }

echo "[INFO]: sign $BOOTFILE with example keys"
stconfig sign $WORKDIR/$BOOTFILE $WORKDIR/signing/signing-key-1.key $WORKDIR/signing/signing-key-1.cert
stconfig sign $WORKDIR/$BOOTFILE $WORKDIR/signing/signing-key-2.key $WORKDIR/signing/signing-key-2.cert
stconfig sign $WORKDIR/$BOOTFILE $WORKDIR/signing/signing-key-3.key $WORKDIR/signing/signing-key-3.cert

echo "[INFO]: upload $WORKDIR/$BOOTFILE to $SERVER"
scp $WORKDIR/$BOOTFILE root@$SERVER:/var/www/testdata/ || { echo -e "upload via scp $failed"; exit 1; }
echo "[INFO]: successfully uploaded signed $BOOTFILE to $SERVER"
