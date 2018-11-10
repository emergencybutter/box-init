#!/bin/bash

# Make and mount an encrypted volume with a discarded key backed by a file on
# disk.

set -eu

if [[ "$#" -ne 2 ]]; then
	echo "$0 size_in_g volume_name"
	exit 1
fi

SIZE_G=$1
VOLUME_NAME=$2

fallocate -l ${SIZE}G /mnt/"${VOLUME_NAME}"
mkdir /mnt/ram
mount -t ramfs /dev/ram /mnt/ram
dd if=/dev/urandom bs=256 count=1 > /mnt/ram/key
cat /mnt/ram/key | cryptsetup --key-file=- luksFormat /mnt/"${VOLUME_NAME}"
cat /mnt/ram/key | cryptsetup --key-file=- luksOpen /mnt/"${VOLUME_NAME}" "${VOLUME_NAME}"
shred --remove --zero /mnt/ram/key
umount /mnt/ram
mkfs.ext4 -q /dev/mapper/"${VOLUME_NAME}"
mount /dev/mapper/"${VOLUME_NAME}" /home
