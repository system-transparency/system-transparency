#!/bin/bash 

# Add standard user, add admin to sudo group and set password
useradd admin -m -s /bin/bash
usermod -a -G sudo admin
echo 'admin:$1$1isJmq7P$8eXDgvusVClLkgsBaZDGW1' | chpasswd -e

trap - EXIT