#!/bin/bash

VERSION="2.3.0p9"

if [ $# -gt 0 ]; then
  VERSION="$1"
fi

start_time=$(date +%s)

echo "`date +%Y-%m-%d_%H-%M-%S` building Check_MK ${VERSION}..."

echo "updating the build system ..."
apt-get -y update && apt-get -y upgrade

cd /opt/build-mk

if [ ! -d check-mk-raw-${VERSION}.cre ]; then
   echo "checking if check-mk source exists ..."
   if [ ! -f check-mk-raw-${VERSION}.cre.tar.gz ]; then
      echo "getting check-mk source ..."
      wget -q https://download.checkmk.com/checkmk/${VERSION}/check-mk-raw-${VERSION}.cre.tar.gz
   fi
   echo "untar check-mk source ..."
   tar xfz check-mk-raw-${VERSION}.cre.tar.gz
fi

# get check_mk for windows artifact extraction
if [ ! -f check-mk-cloud-${VERSION}_0.kinetic_amd64.deb ]; then
    wget https://download.checkmk.com/checkmk/${VERSION}/check-mk-cloud-${VERSION}_0.noble_amd64.deb   ### Update to noble
fi

# # create symlink to c++-12 compiler if not exists
# if [ ! -f /usr/bin/g++-12 ]; then
#    echo "create symlink to c++-12 ..."
#    ln -sf /usr/bin/g++ /usr/bin/g++-12
# fi

# # create symlink to c++-13 compiler if not exists
# if [ ! -f /usr/bin/g++-13 ]; then
#    echo "create symlink to c++-13 ..."
#    ln -sf /usr/bin/g++ /usr/bin/g++-13
# fi

#python3.12 -m pip install --upgrade pip --break-system-packages

export USE_EXTERNAL_PIPENV_MIRROR=true

echo "going to check-mk source path ...."
cd check-mk-raw-${VERSION}.cre

# patch files
#echo "installing patches ...."
# patch -p0 < ../patches/defines.make-use-official-python-mirror.patch
# patch -p0 < ../patches/Makefile-reduce-webpack-memory-consumption.patch
# patch -p0 < ../patches/Makefile-replace-npm-clean-install-with-install.patch
# patch -p0 < ../patches/omd-Makefile-remove-module-navicli.patch
# patch -p0 < ../patches/python-make-add-fno-semantic-interposition.patch
# patch -p0 < ../patches/python-make-set-aarch64-architecture.patch
# patch -p0 < ../patches/protobuf-make-add-latomic.patch
# patch -p0 < ../patches/pipfile-remove-entries.patch
# patch -p0 < ../patches/pipfile-update-pymssql.patch
# patch -p0 < ../patches/xmlsec1-fix-source-url.patch
# patch -p0 < ../patches/bazel-set-aarch64-architecture.patch
# patch -p0 < ../patches/modify-heirloom-src-url.patch
# patch -p0 < ../patches/modify-path-fake-windows.patch


# Install all .patch files that dont start with 'ZZZ__'
echo "installing patches ...."
for FILE in "../patches/"*.patch; do
   if [ -f "$FILE" ]; then
      BASENAME=$(basename "$FILE")
      if [[ "$BASENAME" != ZZZ___* ]]; then            
         patch -f -p0 < $FILE
      fi
   fi
done

./configure

echo "prepare windows artifacts ..."
ar x ../check-mk-cloud-${VERSION}_0.noble_amd64.deb
tar -I zstd -xf data.tar.zst
rm -rf agents/windows
mv opt/omd/versions/${VERSION}.cce/share/check_mk/agents/windows agents/

echo "updating nagios archive for supporting aarch64 ..."
tar xzf omd/packages/nagios/nagios-3.5.1.tar.gz -C /tmp
cp /usr/share/misc/config.guess /tmp/nagios-3.5.1/
tar czf omd/packages/nagios/nagios-3.5.1.tar.gz -C /tmp nagios-3.5.1
rm -rf /tmp/nagios-3.5.1

echo "updating pnp4nagios archive for supporting aarch64 ..."
tar xzf omd/packages/pnp4nagios/pnp4nagios-0.6.26.tar.gz -C /tmp
cp /usr/share/misc/config.guess /tmp/pnp4nagios-0.6.26/
tar czf omd/packages/pnp4nagios/pnp4nagios-0.6.26.tar.gz -C /tmp pnp4nagios-0.6.26
rm -rf /tmp/pnp4nagios-0.6.26

echo "updating stunnel archive for supporting aarch64 ..."
tar xzf omd/packages/stunnel/stunnel-5.63.tar.gz -C /tmp
cp /usr/share/misc/config.guess /tmp/stunnel-5.63/
tar czf omd/packages/stunnel/stunnel-5.63.tar.gz -C /tmp stunnel-5.63
rm -rf /tmp/stunnel-5.63

echo "updating snap7 archive for supporting aarch64 ..."
tar xzf omd/packages/snap7/snap7-1.4.2.tar.gz -C /tmp
cp /tmp/snap7-1.4.2/build/unix/arm_v6_linux.mk /tmp/snap7-1.4.2/build/unix/aarch64_linux.mk
sed -i  's/arm_v6/aarch64/' /tmp/snap7-1.4.2/build/unix/aarch64_linux.mk
tar czf omd/packages/snap7/snap7-1.4.2.tar.gz -C /tmp snap7-1.4.2
rm -rf /tmp/snap7-1.4.2

# setup pipenv
bash buildscripts/infrastructure/build-nodes/scripts/install-pipenv.sh

echo "starting make deb ..."
# compile and package
make deb DEBFULLNAME="FloTheSysAdmin" DEBEMAIL="FloTheSysadmin@protonmail.com"

if [ $? -eq 0 ]; then
    cp check-mk-raw-${VERSION}*.deb /opt/build-mk/debs/
    cd ..
    echo "`date +%Y-%m-%d_%H-%M-%S` SUCCESS :-)"
    end_time=$(date +%s)
    elapsed=$(( end_time - start_time ))
    eval "echo Elapsed time: $(date -ud "@$elapsed" +'$((%s/3600/24)) days %H hr %M min %S sec')"
fi
