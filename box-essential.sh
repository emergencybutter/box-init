#!/bin/bash

# Initialize a new debian machine/vm

set -eu

cd $(dirname $0)

bash ./box-iptables.sh

echo 'Acquire::PDiffs "false";' > /etc/apt/apt.conf.d/50pdiff
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y update > /dev/null
apt-get -q -y \
	-o Dpkg::Options::="--force-confdef" \
	-o Dpkg::Options::="--force-confold" \
	dist-upgrade > /dev/null
apt-get -q -y \
	-o Dpkg::Options::="--force-confdef" \
	-o Dpkg::Options::="--force-confold" install iptables-persistent
