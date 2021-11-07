#!/bin/bash

set -Eexufo pipefail

env

pacman-key --init
pacman-key --populate archlinuxarm

echo 'Server = http://mirror.archlinuxarm.org/$arch/$repo' > /etc/pacman.d/mirrorlist
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 8/' /etc/pacman.conf

pacman -Sy --noconfirm arch-install-scripts binutils curl

pacstrap /mnt base linux-aarch64 $(cat /pkg.lst)

sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 8/' /mnt/etc/pacman.conf
sed -i 's/#Color/Color/' /mnt/etc/pacman.conf

echo root:root | chroot /mnt chpasswd

cp /ssh_host_ed25519_key /mnt/etc/ssh/ssh_host_ed25519_key
chmod 0400 /mnt/etc/ssh/ssh_host_ed25519_key
sed -i 's|#HostKey /etc/ssh/ssh_host_ed25519_key|HostKey /etc/ssh/ssh_host_ed25519_key|' /mnt/etc/ssh/sshd_config
sed -i 's/#PermitRootLogin/PermitRootLogin/' /mnt/etc/ssh/sshd_config

cat > /mnt/etc/systemd/network/20-wired.network <<EOF
[Match]
Name=enp0s1

[Network]
Address=$IP_ADDR/24
Gateway=192.168.64.1
EOF

cat > /mnt/etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

chroot /mnt systemctl enable systemd-networkd
chroot /mnt systemctl enable systemd-timesyncd
chroot /mnt systemctl enable sshd
chroot /mnt systemctl enable docker

mkdir /mnt/root/.ssh
echo "$PUB_KEY" > /mnt/root/.ssh/authorized_keys
chmod -R og-rwx /mnt/root/.ssh

echo "alias ll='ls -lah --color=always'" >> /mnt/root/.profile

cd /tmp
deb=$(curl -sSL https://deb.debian.org/debian/pool/main/q/qemu/ | grep -oP '(?<=href=")qemu-user-static_.*_arm64.deb(?=")' | sort | tail -n 1)
curl -sSL "https://deb.debian.org/debian/pool/main/q/qemu/$deb" > "$deb"
ar x "$deb"
tar -xvf data.tar.xz ./usr/bin/qemu-x86_64-static
mkdir -p /mnt/opt/binfmt/
cp ./usr/bin/qemu-x86_64-static /mnt/opt/binfmt/x86_64-binfmt-P
echo ":x86_64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/opt/binfmt/x86_64-binfmt-P:OCFP" > /mnt/etc/binfmt.d/x86_64.conf
