#!/bin/bash

SERVER="mullvad.9esec.io"
BOOTFILE="stboot.zip"
WORKDIR="$PWD/../configs/example/"

# configtool parameter
MANIFEST="$WORKDIR/manifest.json"

echo "[INFO]: cleaning up"
rm -f $WORKDIR/$BOOTFILE || { echo "old $BOOTFILE cannot be removed"; exit 1; }
ssh -t root@$SERVER 'rm -f /var/www/testdata/bc.zip; exit' || { echo "old $BOOTFILE cannot be removed on $SERVER"; exit 1; }

echo "[INFO]: pack $MANIFEST and other bootfiles into $BOOTFILE"
stconfig create $MANIFEST -o $WORKDIR/$BOOTFILE || { echo 'stconfig failed'; exit 1; }
echo "[INFO]: sign $BOOTFILE with all available keys (hardcoded right now)"
stconfig sign $WORKDIR/$BOOTFILE $WORKDIR/signing/signing-key-1.key $WORKDIR/signing/signing-key-1.cert
stconfig sign $WORKDIR/$BOOTFILE $WORKDIR/signing/signing-key-2.key $WORKDIR/signing/signing-key-2.cert
stconfig sign $WORKDIR/$BOOTFILE $WORKDIR/signing/signing-key-3.key $WORKDIR/signing/signing-key-3.cert

echo "[INFO]: upload $BOOTFILE tp $SERVER"
scp $WORKDIR/$BOOTFILE root@$SERVER:/var/www/testdata/ || { echo 'upload via sco faid'; exit 1; }
echo "[INFO]: successfully uploaded signed $BOOTFILE to $SERVER"
