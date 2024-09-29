#!/bin/bash

# copy script in the root-filesystem "cp build_hostapd.sh $rootdir/root/"
# chroot $rootdir /root/build_hostapd.sh
# this can be also done in travis-ci: https://github.com/ahmed-dinar/travis-chroot

if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ]; then
	echo "We are chrooted! continue building..."

	apt update
	apt -y install --no-install-recommends pkg-config libssl-dev libreadline-dev libpcsclite-dev libnl-route-3-dev libnl-genl-3-dev libnl-3-dev libncurses5-dev libdbus-1-dev docbook-utils docbook-to-man
	apt -y install --no-install-recommends git gcc make rsync file

	echo "clone/install linux-headers"
	cd /usr/src
	git clone --depth=1 --no-checkout --filter=blob:none --sparse https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
	cd linux
	git sparse-checkout init --cone
	git sparse-checkout set include scripts arch/arm/include arch/arm64/include
	git checkout
	make -j4 headers_install INSTALL_HDR_PATH=/usr/local/

	echo "build hostapd"
	cd /usr/src
	mkdir -p hostapd
	cd hostapd/
	git clone http://w1.fi/hostap.git
	cd hostap/hostapd/
	cp defconfig .config
	sed -i 's/#CONFIG_SAE/CONFIG_SAE/' .config
	sed -i 's/#CONFIG_ACS/CONFIG_ACS/' .config
	make -j4
	file hostapd hostapd_cli
	tar -czf hostapd.tar.gz hostapd hostapd_cli

	echo "build wpa_supplicant"
	cd ../wpa_supplicant/
	cp defconfig .config
	sed -i 's/#CONFIG_MESH/CONFIG_MESH/' .config
	make -j4
	file wpa_supplicant
else
  echo "no chroot...exiting..."
fi
