#!/bin/sh

# remove ssh keys
rm -f /etc/ssh/ssh_host*

# clear installation log
find /var/log -type f | while read -r line ; do rm "$line" ; done

# remove ldconfig cache
rm /var/cache/ldconfig/aux-cache

# kill systemd catalog file
rm /var/lib/systemd/catalog/database

# remove systemd machine id
rm /etc/machine-id

# FIXME: remove this password
echo 'root:$5$iog/g/SUY7Pm0L$vjoNOFeV5OHSZyxNDsLmZpI0XorPu8iZixBLvLBP6S5' | chpasswd -e

# remove initrd as its not needed nor reproducible
rm -rf /var/lib/initramfs-tools/*
rm /boot/initrd.img*
