#!/bin/bash

# Handful functions when installing debian machines remotely.

set -eu

function no-pdiffs() {
	echo 'Acquire::PDiffs "false";' > /etc/apt/apt.conf.d/50pdiff
}

function non-interactive-apt() {
	DEBIAN_FRONTEND=noninteractive apt-get -q -y \
		-o Dpkg::Options::="--force-confdef" \
		-o Dpkg::Options::="--force-confold" \
		"$@" > /dev/null
}
