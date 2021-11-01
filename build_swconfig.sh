#!/bin/bash

# copy script in the root-filesystem "cp build_swconfig.sh $rootdir/root/"
# chroot $rootdir /root/build_swconfig.sh

if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ]; then
	echo "We are chrooted! continue building..."

	apt update
	apt -y install git gcc make
	apt -y install build-essential fakeroot devscripts debhelper libnl-3-dev libnl-genl-3-dev
	cd /usr/src
	git clone https://github.com/jekader/swconfig
	cd swconfig/
	bash build.sh
#	make
#	PRFX=$(pwd)/install
#	make PREFIX=$PRFX SBINDIR=$PRFX/sbin install
	#file ip/ip
else
  echo "no chroot...exiting..."
fi
