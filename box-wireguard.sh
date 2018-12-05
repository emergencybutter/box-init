#!/bin/bash

# Install sid wireguard on a debian stretch

set -eu
cd $(dirname $0)
source ./box-lib.sh

no-pdiff
echo "deb http://deb.debian.org/debian/ unstable main" \
	> /etc/apt/sources.list.d/unstable-wireguard.list
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' \
	> /etc/apt/preferences.d/limit-unstable
non-interactive-apt update
non-interactive-apt install linux-headers-$(uname -r)
non-interactive-apt install wireguard

iptables -A INPUT -p udp --dport 51820 -m state --state NEW -j ACCEPT
iptables -A FORWARD -i wg0 -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward
