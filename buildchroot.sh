#!/bin/bash
#sudo apt-get install qemu-user-static debootstrap binfmt-support

set -x

distro=bullseye
#distro=buster
#distro=stretch
arch=armhf
#arch=arm64
#arch=amd64
#arch=x86_64

if [[ -n "$1" ]];then
	echo "\$1:"$1
	if [[ "$1" =~ armhf|arm64 ]];then
		echo "setting arch"
		arch=$1
	fi
fi

targetdir=$(pwd)/debian_${distro}_${arch}
if [[ -e $targetdir ]]; then exit;fi
mkdir -p $targetdir
sudo chown root:root $targetdir
#mount | grep 'proc\|sys'
sudo debootstrap --arch=$arch --foreign $distro $targetdir
case "$arch" in
	"armhf")
		sudo cp /usr/bin/qemu-arm-static $targetdir/usr/bin/
	;;
	"arm64")
	#for r64 use
		sudo cp /usr/bin/qemu-aarch64-static $targetdir/usr/bin/
	;;
	"amd64")
		;;
	*) echo "unsupported arch $arch";;
esac
sudo cp /etc/resolv.conf $targetdir/etc
LANG=C

#sudo mount -t proc none $targetdir/proc/
#sudo mount -t sysfs sys $targetdir/sys/
#sudo mount -o bind /dev $targetdir/dev/
sudo chroot $targetdir /debootstrap/debootstrap --second-stage
ret=$?
if [[ $ret -ne 0 ]];then
	#sudo umount $targetdir/proc/
	#sudo umount $targetdir/sys/
	#sudo rm -rf $targetdir/*
	exit $ret;
fi
langcode=de
sudo chroot $targetdir tee "/etc/apt/sources.list" > /dev/null <<EOF
deb http://ftp.$langcode.debian.org/debian $distro main contrib non-free
deb-src http://ftp.$langcode.debian.org/debian $distro main contrib non-free
deb http://ftp.$langcode.debian.org/debian $distro-updates main contrib non-free
deb-src http://ftp.$langcode.debian.org/debian $distro-updates main contrib non-free
deb http://security.debian.org/debian-security $distro/updates main contrib non-free
deb-src http://security.debian.org/debian-security $distro/updates main contrib non-free
EOF

sudo tar -czf debian_${distro}_${arch}.tar.gz $targetdir
