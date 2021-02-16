#!/bin/bash

set -o errexit
set -o nounset
# set -o xtrace

# remove systemd machine id
rm -f ${ROOTDIR}/etc/machine-id

# remove ssh keys
rm -f ${ROOTDIR}/etc/ssh/ssh_host*

# remove ldconfig cache
rm -f ${ROOTDIR}/var/cache/ldconfig/aux-cache

# kill systemd catalog file
rm -rf ${ROOTDIR}/var/lib/systemd/catalog/database

# clear installation log
find ${ROOTDIR}/var/log -type f | while read -r line ; do rm -f "$line" ; done

# remove pycache
find ${ROOTDIR} -type d -name __pycache__ | while read -r line ; do rm -rf "$line" ; done

# remove initrd as its not needed nor reproducible
rm -rf ${ROOTDIR}/var/lib/initramfs-tools/*
rm -f ${ROOTDIR}/boot/initrd.img*

trap - EXIT
