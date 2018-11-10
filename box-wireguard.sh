#!/bin/bash

# Install sid wireguard on a debian stretch

set -eu

cd $(dirname $0)

echo 'Acquire::PDiffs "false";' > /etc/apt/apt.conf.d/50pdiff
export DEBIAN_FRONTEND=noninteractive

echo "deb http://deb.debian.org/debian/ unstable main" \
	> /etc/apt/sources.list.d/unstable-wireguard.list
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' \
	> /etc/apt/preferences.d/limit-unstable
apt-get update
apt-get -q -y \
	-o Dpkg::Options::="--force-confdef" \
	-o Dpkg::Options::="--force-confold" \
	install linux-headers-$(uname -r)
apt-get -q -y \
	-o Dpkg::Options::="--force-confdef" \
	-o Dpkg::Options::="--force-confold" \
	install wireguard
