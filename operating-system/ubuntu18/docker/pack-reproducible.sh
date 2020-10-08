#!/bin/sh
#
# pack a debian reproducible
# MIT
# 2019 Alexander Couzens <lynxis@fe80.eu>


if [ -z "$SOURCE_DATE_EPOCH" ] ; then
  echo "Environment SOURCE_DATE_EPOCH is not set!" >&2
  exit 1
fi

tar c "--mtime=@$SOURCE_DATE_EPOCH" --numeric-owner -C "$ROOTDIR" . | bzip2 -c -9 > "$ARTIFACTDIR/$1.tar.bz2"
cd "$ROOTDIR" || exit 1

# move kernel out of the image
mv "$ROOTDIR"/boot/vmlinuz-4.15.0-20-generic "$ARTIFACTDIR/"
find . | while read -r line ; do touch -hcd "@$SOURCE_DATE_EPOCH" "$line" ; done
find . -mindepth 1 -printf '%P\0' | sort -z | cpio --reproducible -0 -o -H newc | gzip -9 -n > "$ARTIFACTDIR/$1.cpio.gz"
