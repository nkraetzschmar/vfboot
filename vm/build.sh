#!/bin/sh

set -euf

exec 3>&1
exec 1>&2

set -x

env

apk update
apk add curl e2fsprogs e2fsprogs-extra lz4

mkdir /chroot

curl -sSL http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz | gzip -d | tar -C /chroot -x

mount --bind /chroot /chroot
rm /chroot/etc/resolv.conf
touch /chroot/etc/resolv.conf
mount --bind /etc/resolv.conf /chroot/etc/resolv.conf
mount -t proc /proc /chroot/proc
mount --make-rslave --rbind /sys /chroot/sys
mount --make-rslave --rbind /dev /chroot/dev
mount --make-rslave --rbind /run /chroot/run

touch /chroot/bootstrap.sh
mount --bind /bootstrap.sh /chroot/bootstrap.sh
touch /chroot/pkg.lst
mount --bind /pkg.lst /chroot/pkg.lst
touch /chroot/ssh_host_ed25519_key
mount --bind /ssh_host_ed25519_key /chroot/ssh_host_ed25519_key
chroot /chroot env -i IP_ADDR="$IP_ADDR" PUB_KEY="$PUB_KEY" /bootstrap.sh
umount /chroot/bootstrap.sh
umount /chroot/pkg.lst
umount /chroot/ssh_host_ed25519_key

truncate -s "$SIZE" /img
mke2fs -t ext4 -d /chroot/mnt /img
e2fsck -y -f /img
resize2fs -M /img

lz4 < /img >&3
