# lxc builds

This document describes how to setup lxc on a plain debian buster. lxc containers behave similiar to full VMs, but only use kernel subsystems to protect the container from accessing the host installation.
This howto is seperated into the following steps

- Install required packages
- Setup the network

## Required packages

```
apt-get update
apt-get install dnsmasq lxc bridge-utils
```

## Setup the host network

Create a virtual bridge interface with the ip network 10.99.0.0/24,
dhcp server and nat (masquerading)

```
cat > /etc/network/interfaces.d/lxc.conf <<EOF
auto sysbr
iface sysbr inet static
	address 10.99.0.1/24
	bridge_ports nonexist
	post-up iptables -t nat -I POSTROUTING -j MASQUERADE -s 10.99.0.0/24
	post-up iptables -I FORWARD -i sysbr
	post-up iptables -I FORWARD -o sysbr
	post-up echo 1 > /proc/sys/net/ipv4/ip_forward
EOF
ifup sysbr

# configure dnsmasq
cat > /etc/dnsmasq.conf <<EOF
dhcp-range=10.99.0.10,10.99.0.254,2h
EOF
systemctl enable dnsmasq
systemctl restart dnsmasq

# default lxc interface
cat > /etc/lxc/default.conf <<EOF
lxc.net.0.type = veth
lxc.net.0.link = sysbr
lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 1
EOF
```

## Use lxc to build an image

```
lxc-create --name builder -t download -- -d debian -a amd64 --release buster
lxc-start --name builder
# let dhcp work
sleep 5
lxc-attach --name builder -- sh -c 'apt-get update && apt-get install -y --no-install-recommends debos git ca-certificates cpio bzip2'
lxc-attach --name builder -- sh -c 'cd /root && git clone https://github.com/system-transparency/build'
lxc-attach --name builder -- sh -c 'cd /root/build/debian && ./build.sh'
cp /var/lib/lxc/builder/rootfs/root/build/debian/out/* .
```
