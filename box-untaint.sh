#!/bin/bash

# Usage:
# Setup a large unused parition somewhere on your disk, say /dev/sdaX.
# untain.sh init /dev/sdaX
# Reboot.

set -eu

# SSH_KEY='ecdsa-sha2-nistp256 AAAA....'
SSH_KEY=

function install_ssh_key() {
	mkdir -p /root/.ssh
	cat > /root/.ssh/authorized_keys <<-EOF
	${SSH_KEY}
	EOF
	chmod 644 /root/.ssh/authorized_keys
}

function log() {
	echo "$(date)" "$@"
}

function init() {
	log "init"
	install_ssh_key
	grep -q '^force-confdef$' /etc/dpkg/dpkg.cfg || \
		echo force-confdef >> /etc/dpkg/dpkg.cfg
	export DEBIAN_FRONTEND=noninteractive
	cat > /etc/apt/sources.list <<-EOF
	deb https://deb.debian.org/debian testing main
	deb-src https://deb.debian.org/debian testing main
	deb https://deb.debian.org/debian-debug testing-debug main
	deb-src https://deb.debian.org/debian-debug testing-debug main

	deb https://deb.debian.org/debian testing-updates main
	deb-src https://deb.debian.org/debian testing-updates main
	EOF
	cat > /etc/apt/apt.conf.d/00install-recommends <<-EOF
	APT::Install-Recommends "false";
	EOF
	apt-get update
}

function install-and-make-bootable() {
	local dev="$1"
	if grep -q "${dev}" /proc/mounts ; then
		umount $(awk '$1 == "'"${dev}"'" { print $2 }' /proc/mounts)
	fi
	mkfs.ext4 "${dev}"
	mkdir -p /install
	mount "${dev}" /install
	apt-get install debootstrap
	log "Running debootstrap"
	debootstrap testing /install https://deb.debian.org/debian/
	log "debootstrap done, copying essential configs."
	cp /etc/resolv.conf /install/etc/resolv.conf
	mkdir -p /install/etc/systemd/network
	cp /etc/systemd/network/* /install/etc/systemd/network
	cp /etc/hosts /install/etc/hosts
	cat > /install/etc/fstab <<-EOF
	# <file system> <mount point>   <type>  <options>       <dump>  <pass>
	${dev}       /         ext4    errors=remount-ro,relatime      0       1
	proc            /proc     proc    defaults                        0       0
	sysfs           /sys      sysfs   defaults                0       0
	tmpfs           /dev/shm  tmpfs   defaults        0       0
	devpts          /dev/pts  devpts  defaults        0       0
	EOF
	mount --bind /dev /install/dev
	mount --bind /run /install/run
	cp "$0" /install/root
	chroot /install bash "/root/$(basename "$0")" in-chroot
}

in-chroot() {
	mount proc /proc -t proc
	mount sysfs /sys -t sysfs

	systemctl enable systemd-networkd

	apt-get install -y locales
	echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections
	echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections
	rm "/etc/locale.gen"
	dpkg-reconfigure --frontend noninteractive locales
	apt-get install -y grub-pc linux-image-amd64 ssh
	update-grub
	grub-install /dev/sda
	log "grub installed"
	log "SSH host keys:"
	for k in /etc/ssh/ssh_host_*.pub; do
		ssh-keygen -l -f $k || true
	done
}

case "$1" in
init)
	init
	install-and-make-bootable "$2"
	;;
in-chroot)
	init
	in-chroot
	;;
*)
	log "Error, usage $0 [init /dev/sdxx|in-chroot]"
esac
