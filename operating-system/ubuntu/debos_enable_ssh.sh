#!/bin/bash

# Enable password authentication for ssh server
sed -i  's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config

#Enable ssh server
systemctl enable ssh



