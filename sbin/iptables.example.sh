#!/bin/bash

outside_net_dev=$1
shift 1
if [ ! -n "$outside_net_dev" -o ! -d /sys/class/net/$outside_net_dev ]; then
     echo "$(basename $0) <outside network dev> [<adding ip1> ...]"
     exit
fi

outside_ip=$(ifconfig $outside_net_dev | grep " inet " | awk '{print $2}')
echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -t nat -A POSTROUTING -s ${outside_ip}/32 -o ${outside_net_dev}  -j MASQUERADE
for add_ip in $*; do
   iptables -t nat -A POSTROUTING -s ${add_ip}/32 -o ${outside_net_dev}  -j MASQUERADE
done
iptables -A INPUT -i ${outside_net_dev} -p TCP --dport ssh -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state NEW -i !${outside_net_dev} -j ACCEPT
iptables -A INPUT -i ${outside_net_dev} -j DROP 
