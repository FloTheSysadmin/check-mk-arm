#!/bin/bash

CHECKMK_VERSION="2.1.0p21"
SNAP7_VERSION="1.4.2"

if [ $# -gt 0 ]; then
  CHECKMK_VERSION="$1"
fi

echo "building Check_MK ${CHECKMK_VERSION}..."

# get check_mk build dependencies
if [ ${INSTALL_DEPENDENCIES:-0} -eq 1 ]; then
    apt-get -y install apache2 build-essential chrpath cmake debhelper dnsutils dpatch flex fping freetds-dev git \
        git-buildpackage make rpcbind rrdtool smbclient snmp apache2-dev default-libmysqlclient-dev dietlibc-dev \
        libboost-all-dev libboost-dev libcurl4-openssl-dev libcloog-ppl1 libdbi-dev libevent-dev libffi-dev \
        libfreeradius-dev libgd-dev libglib2.0-dev libgnutls28-dev libgsf-1-dev libkrb5-dev libmcrypt-dev \
        libncurses-dev libpango1.0-dev libpcap-dev libperl-dev libpq-dev libreadline-dev librrd-dev libsasl2-dev \
        libsodium-dev libsqlite3-dev libssl-dev libxml2-dev libxmlsec1-dev patchelf python3-pip tk-dev uuid-dev
fi

# get check_mk sources
if [ ! -f check-mk-raw-${CHECKMK_VERSION}.cre.tar.gz ]; then
    wget -q https://download.checkmk.com/checkmk/${CHECKMK_VERSION}/check-mk-raw-${CHECKMK_VERSION}.cre.tar.gz
fi
rm -rf check-mk-raw-${CHECKMK_VERSION}.cre
tar xfz check-mk-raw-${CHECKMK_VERSION}.cre.tar.gz

# configure check_mk
cd check-mk-raw-${CHECKMK_VERSION}.cre
./configure

# apply patches
patch -p0 < ../omd-Makefile-remove-module-navicli.patch
patch -p0 < ../python-make-add-fno-semantic-interposition.patch
patch -p0 < ../python-make-set-arm-architecture.patch
patch -p0 < ../protobuf-make-add-latomic.patch
patch -p0 < ../pipfile-remove-pbr.patch
patch -p0 < ../pipfile-remove-playwright.patch

# prepare snap7
tar xvzf omd/packages/snap7/snap7-${SNAP7_VERSION}.tar.gz -C omd/packages/snap7
cp omd/packages/snap7/snap7-${SNAP7_VERSION}/build/unix/arm_v6_linux.mk omd/packages/snap7/snap7-${SNAP7_VERSION}/build/unix/armv6l_linux.mk
ln -s arm_v6-linux omd/packages/snap7/snap7-${SNAP7_VERSION}/build/bin/armv6l-linux
cp omd/packages/snap7/snap7-${SNAP7_VERSION}/build/unix/arm_v7_linux.mk omd/packages/snap7/snap7-${SNAP7_VERSION}/build/unix/armv7l_linux.mk
ln -s arm_v7-linux omd/packages/snap7/snap7-${SNAP7_VERSION}/build/bin/armv7l-linux
tar czf omd/packages/snap7/snap7-${SNAP7_VERSION}.tar.gz -C omd/packages/snap7 snap7-${SNAP7_VERSION}

# setup pipenv
bash buildscripts/infrastructure/build-nodes/scripts/install-pipenv.sh

# compile and package
make deb DEBFULLNAME="Christian Hofer" DEBEMAIL=chrisss404@gmail.com

# cleanup
if [ $? -eq 0 ]; then
    mv check-mk-raw-${CHECKMK_VERSION}* ..
    cd ..
    rm -rf check-mk-raw-${CHECKMK_VERSION}.cre
fi
