#!/bin/bash

# copy script in the root-filesystem "cp build_hostapd.sh $rootdir/root/"
# chroot $rootdir /root/build_hostapd.sh

if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ]; then
	echo "We are chrooted! continue building..."

	apt update
	apt -y install git gcc make
	apt -y install pkg-config libmnl-dev libreadline-dev libpcsclite-dev libnl-route-3-dev libnl-genl-3-dev libnl-3-dev libncurses5-dev bison flex
	cd /usr/src
	git clone https://github.com/frank-w/iproute2
	cd iproute2/
	make
	PRFX=$(pwd)/install
	make PREFIX=$PRFX SBINDIR=$PRFX/sbin install
	#file ip/ip
	cd $PRFX
	tar -czf ../iproute2.tar.gz .
	tar -tzf ../iproute2.tar.gz
else
  echo "no chroot...exiting..."
fi
