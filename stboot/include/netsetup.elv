ip addr add 10.0.2.15/24 dev eth0
ip link set eth0 up
ip route add default via 10.0.2.2/24 dev eth0

ip addr
ip route
