#!/bin/bash
#debian build instructions:
#http://cheatsheet.logicalwebhost.com/iperf-network-testing/

#find ./ | grep libiperf.so.0
#  ./usr/src/iperf/iperf/src/.libs/libiperf.so.0.0.0
#  ./usr/src/iperf/iperf/src/.libs/libiperf.so.0
#  ./usr/local/lib/libiperf.so.0.0.0
#  ./usr/local/lib/libiperf.so.0
#echo $LD_LIBRARY_PATH

#if you get a blank, the path does not work, so do:
#LD_LIBRARY_PATH=/usr/local/lib
#LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/libiperf.so.0
#export LD_LIBRARY_PATH

TAG="3.17.1"
# copy script in the root-filesystem "cp build_iperf3.sh $rootdir/root/"
# chroot $rootdir /root/build_hostapd.sh

if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ]; then
	echo "We are chrooted! continue building..."

	apt update
	apt -y install build-essential git
	#apt -y install pkg-config libmnl-dev libreadline-dev libpcsclite-dev libnl-route-3-dev libnl-genl-3-dev libnl-3-dev libncurses5-dev bison flex
	cd /usr/src
	git clone https://github.com/esnet/iperf.git
	cd iperf/
	if [[ -n "$TAG" ]];then
		git checkout $TAG
	fi
	PRFX=$(pwd)/install
	./configure --enable-static-bin --prefix=$PRFX #--bindir=$PRFX
	make
	#make PREFIX=$PRFX SBINDIR=$PRFX/sbin install
	make install

	cd $PRFX
	tar -czf ../iperf.tar.gz .
	tar -tzf ../iperf.tar.gz
else
  echo "no chroot...exiting..."
fi
