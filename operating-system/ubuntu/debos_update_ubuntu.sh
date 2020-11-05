#!/bin/sh

if [ $1 = 18 ]; then
    UBUNTU="bionic"
fi

if [ $1 = 20 ]; then
    UBUNTU="focal"
fi

#Uncommend bionic or focal lines for apt.
sed -i "/$UBUNTU/s/^#//" /etc/apt/sources.list

# Update and dist-upgrade the installation to the latest stuff
apt-get update -qq && apt-get dist-upgrade -qq