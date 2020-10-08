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

# Copy netplan file to correct location
cp -r /overlays/netplan /etc

# delete overlays directory
rm -Rf /overlays

# Add standard user, add admin to sudo group and set password
useradd admin -m -s /bin/bash
usermod -a -G sudo admin
echo 'admin:$1$1isJmq7P$8eXDgvusVClLkgsBaZDGW1' | chpasswd -e

# Enable password authentication for ssh server
sed -i  's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config

#Enable ssh server
systemctl enable ssh

# remove initrd as its not needed nor reproducible
rm -rf /var/lib/initramfs-tools/*
rm /boot/initrd.img*
