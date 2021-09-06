#!/bin/bash

# Initialize a new debian machine/vm

set -eu
cd $(dirname $0)
source ./box-lib.sh

function iptables() {
	/sbin/iptables "$@"
}

function load-iptables-config() {
	# Flush the tables to apply changes
	iptables -F
	iptables -t nat -F POSTROUTING

	# Default policy to drop 'everything' but our output to internet
	iptables -P FORWARD DROP
	iptables -P INPUT   DROP
	iptables -P OUTPUT  ACCEPT

	# Allow established connections (the responses to our outgoing traffic)
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

	# Allow local programs that use loopback (Unix sockets)
	iptables -A INPUT -s 127.0.0.0/8 -d 127.0.0.0/8 -i lo -j ACCEPT

	iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
	iptables -A INPUT -p icmp --icmp-type 8 -m state --state NEW -j ACCEPT

	iptables -tnat -A POSTROUTING -o ens2 -j MASQUERADE

	# Log
	iptables -A INPUT -j LOG --log-prefix "INPUT:"
	iptables -A FORWARD -j LOG  --log-prefix "FORWARD:"


	# First Flush and delete all:
	ip6tables -F INPUT
	ip6tables -F OUTPUT
	ip6tables -F FORWARD

	ip6tables -F
	ip6tables -X

	# DROP all incomming traffic
	ip6tables -P INPUT DROP
	ip6tables -P OUTPUT ACCEPT
	ip6tables -P FORWARD DROP

	# Filter all packets that have RH0 headers:
	ip6tables -A INPUT -m rt --rt-type 0 -j DROP
	ip6tables -A FORWARD -m rt --rt-type 0 -j DROP
	ip6tables -A OUTPUT -m rt --rt-type 0 -j DROP

	# Allow anything on the local link
	ip6tables -A INPUT  -i lo -j ACCEPT
	ip6tables -A OUTPUT -o lo -j ACCEPT

	# Allow established, related packets back in
	ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	ip6tables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

	# Allow multicast
	ip6tables -A INPUT -d ff00::/8 -j ACCEPT
	ip6tables -A OUTPUT -d ff00::/8 -j ACCEPT

	# Allow dedicated  ICMPv6 packettypes, do this in an extra chain because we need it everywhere
	ip6tables -N AllowICMPs
	# Destination unreachable
	ip6tables -A AllowICMPs -p icmpv6 --icmpv6-type 1 -j ACCEPT
	# Packet too big
	ip6tables -A AllowICMPs -p icmpv6 --icmpv6-type 2 -j ACCEPT
	# Time exceeded
	ip6tables -A AllowICMPs -p icmpv6 --icmpv6-type 3 -j ACCEPT
	# Parameter problem
	ip6tables -A AllowICMPs -p icmpv6 --icmpv6-type 4 -j ACCEPT
	# Echo Request (protect against flood)
	ip6tables -A AllowICMPs -p icmpv6 --icmpv6-type 128 -m limit --limit 5/sec --limit-burst 10 -j ACCEPT
	# Echo Reply
	ip6tables -A AllowICMPs -p icmpv6 --icmpv6-type 129 -j ACCEPT

	ip6tables -A INPUT -p icmpv6 -j AllowICMPs

	# Log
	ip6tables -A INPUT -j LOG --log-prefix "INPUT-v6:"
	ip6tables -A FORWARD -j LOG  --log-prefix "FORWARD-v6:"
}

no-pdiff
load-iptables-config
non-interactive-apt remove fio unattended-upgrades python3-apt grub-efi-amd64 grub-efi-amd64-bin libglib2.0-0 librbd1 shared-mime-info grub2-common librados2 python-yaml grub-common os-prober python-apt curl python python-minimal mosh python3 python3-minimal perl rename ntp sysstat tmux tcpdump bc bootlogd ethstatus htop ioping iperf lsof make mg netcat ntpdate haveged locate netcat rsync screen socat sudo shunit2
non-interactive-apt autoremove
non-interactive-apt update
non-interactive-apt dist-upgrade
non-interactive-apt install iptables-persistent cryptsetup-bin
