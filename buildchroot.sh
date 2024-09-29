#!/bin/bash
#sudo apt-get install qemu-user-static debootstrap binfmt-support

#debian
name=debian
distro=bookworm
#distro=bullseye
#distro=buster
#distro=stretch

#ubuntu
#name=ubuntu
#distro=noble #24.04
#distro=jammy #22.04

#arch=armhf
arch=arm64
#arch=amd64
#arch=x86_64

#sudo apt install debootstrap qemu-user-static
function checkpkg(){
	echo "checking for needed packages..."
	for pkg in debootstrap qemu-arm-static qemu-aarch64-static; do
		which $pkg >/dev/null;
		if [[ $? -ne 0 ]];then
			echo "$pkg missing";
			exit 1;
		fi;
	done
}

checkpkg

if [[ -n "$1" ]];then
	echo "\$1:"$1
	if [[ "$1" =~ armhf|arm64 ]];then
		echo "setting arch"
		arch=$1
	fi
fi

if [[ -n "$2" ]];then
	echo "\$2:"$2
	if [[ "$2" =~ buster|bullseye ]];then
		echo "setting arch"
		distro=$2
	fi
fi

echo "create chroot '${name} ${distro}' for ${arch}"

#set -x
targetdir=$(pwd)/${name}_${distro}_${arch}
if [[ -e $targetdir ]]; then echo "$targetdir already exists - aborting";exit;fi
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

echo 'root:bananapi' | sudo chroot $targetdir /usr/sbin/chpasswd

langcode=de
if [[ "$name" == "debian" ]];then
sudo chroot $targetdir tee "/etc/apt/sources.list" > /dev/null <<EOF
deb http://ftp.$langcode.debian.org/debian $distro main contrib non-free
deb-src http://ftp.$langcode.debian.org/debian $distro main contrib non-free
deb http://ftp.$langcode.debian.org/debian $distro-updates main contrib non-free
deb-src http://ftp.$langcode.debian.org/debian $distro-updates main contrib non-free
deb http://security.debian.org/debian-security ${distro}-security main contrib non-free
deb-src http://security.debian.org/debian-security ${distro}-security main contrib non-free
EOF
else
sudo chroot $targetdir tee "/etc/apt/sources.list" > /dev/null <<EOF
deb http://ports.ubuntu.com/ubuntu-ports/ $distro main universe restricted multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports/ $distro main universe restricted multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $distro-security main universe restricted multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports/ $distro-security main universe restricted multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $distro-updates main universe restricted multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports/ $distro-updates main universe restricted multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $distro-backports main universe restricted multiverse
deb-src http://ports.ubuntu.com/ubuntu-ports/ $distro-backports main universe restricted multiverse
EOF
fi

sudo chroot $targetdir tee "/etc/fstab" > /dev/null <<EOF
# <file system>		<dir>	<type>	<options>		<dump>	<pass>
/dev/mmcblk0p5		/boot	vfat	errors=remount-ro	0	1
/dev/mmcblk0p6		/	ext4	defaults		0	0
EOF

sudo chroot $targetdir bash -c "apt update; apt install --no-install-recommends -y openssh-server"
echo 'PermitRootLogin=yes'| sudo tee -a $targetdir/etc/ssh/sshd_config

echo 'bpi'| sudo tee $targetdir/etc/hostname

sudo tar -czf ${name}_${distro}_${arch}.tar.gz $targetdir
