#!/bin/bash

set -e
set -x

## Basic variables

CURDIR=$(dirname $(readlink -f $0))
TOPDIR=$(git rev-parse --show-toplevel 2>/dev/null)
RPMDIR=${TOPDIR}/contrib/packages/rpm/el8
VERSION=$(grep '^set(VERSION ' ${TOPDIR}/CMakeLists.txt | sed 's@^set(VERSION \(.*\))@\1@')

## Prepare the build directory
rm -rf ${CURDIR}/rpmbuild
mkdir -p ${CURDIR}/rpmbuild/{BUILD,BUILDROOT,SRPMS,SOURCES,SPECS,RPMS}
chmod a+w ${CURDIR}/rpmbuild/{BUILD,BUILDROOT,SRPMS,RPMS}
[ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled && chcon -Rt container_file_t ${CURDIR}/rpmbuild

rm -rf ${CURDIR}/builddeps
mkdir -p ${CURDIR}/builddeps
chmod a+w ${CURDIR}/builddeps
[ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled && chcon -Rt container_file_t ${CURDIR}/builddeps

## Build libdmx-devel from source
docker run --volume ${CURDIR}/rpmbuild:/home/rpm/rpmbuild --volume ${CURDIR}/builddeps:/home/rpm/builddeps --interactive --tty --rm tigervnc/${DOCKER} \
	bash -c "
	yumdownloader --source libdmx &&
	sudo chown rpm.rpm ~/rpmbuild/* &&
	rpm -i libdmx-*.rpm
	sudo yum-builddep -y /home/rpm/rpmbuild/SPECS/libdmx.spec &&
	rpmbuild -ba ~/rpmbuild/SPECS/libdmx.spec &&
	sudo chown rpm.rpm /home/rpm/builddeps &&
	mv ~/rpmbuild/RPMS/x86_64/libdmx-1.*.rpm ~/builddeps &&
	mv ~/rpmbuild/RPMS/x86_64/libdmx-devel-*.rpm ~/builddeps &&
	sudo chown -R 0.0 ~/rpmbuild &&
	sudo rm -rf ~/rpmbuild/*
	"

## Clean the build directory
rm -rf ${CURDIR}/rpmbuild
mkdir -p ${CURDIR}/rpmbuild/{BUILD,BUILDROOT,SRPMS,SOURCES,SPECS,RPMS,BUILDDEPS}
chmod a+w ${CURDIR}/rpmbuild/{BUILD,BUILDROOT,SRPMS,RPMS,BUILDDEPS}
[ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled && chcon -Rt container_file_t ${CURDIR}/rpmbuild

## Build egl-wayland-devel from source
docker run --volume ${CURDIR}/rpmbuild:/home/rpm/rpmbuild --volume ${CURDIR}/builddeps:/home/rpm/builddeps --interactive --tty --rm tigervnc/${DOCKER} \
	bash -c "
	yumdownloader --source egl-wayland &&
	sudo chown rpm.rpm ~/rpmbuild/* &&
	rpm -i egl-wayland-*.rpm
	sudo yum-builddep -y /home/rpm/rpmbuild/SPECS/egl-wayland.spec &&
	rpmbuild -ba ~/rpmbuild/SPECS/egl-wayland.spec &&
	sudo chown rpm.rpm /home/rpm/builddeps &&
	mv ~/rpmbuild/RPMS/x86_64/egl-wayland-1.*.rpm ~/builddeps &&
	mv ~/rpmbuild/RPMS/x86_64/egl-wayland-devel-*.rpm ~/builddeps &&
	sudo chown -R 0.0 ~/rpmbuild &&
	sudo rm -rf ~/rpmbuild/*
	"

## Clean the build directory
rm -rf ${CURDIR}/rpmbuild
mkdir -p ${CURDIR}/rpmbuild/{BUILD,BUILDROOT,SRPMS,SOURCES,SPECS,RPMS,BUILDDEPS}
chmod a+w ${CURDIR}/rpmbuild/{BUILD,BUILDROOT,SRPMS,RPMS,BUILDDEPS}
[ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled && chcon -Rt container_file_t ${CURDIR}/rpmbuild

## Build xorg-x11-server-source from source
docker run --volume ${CURDIR}/rpmbuild:/home/rpm/rpmbuild --volume ${CURDIR}/builddeps:/home/rpm/builddeps --interactive --tty --rm tigervnc/${DOCKER} \
	bash -c "
	sudo yum -y install ~/builddeps/*.rpm &&
	sudo rm -f ~/builddeps/* &&
	yumdownloader --source xorg-x11-server-Xorg &&
	sudo chown rpm.rpm ~/rpmbuild/* &&
	rpm -i xorg-x11-server-*.rpm
	sudo yum-builddep -y /home/rpm/rpmbuild/SPECS/xorg-x11-server.spec &&
	rpmbuild -ba ~/rpmbuild/SPECS/xorg-x11-server.spec &&
	sudo chown rpm.rpm ~/builddeps &&
	mv ~/rpmbuild/RPMS/noarch/xorg-x11-server-source-*.rpm ~/builddeps &&
	sudo chown -R 0.0 ~/rpmbuild &&
	sudo rm -rf ~/rpmbuild/*
	"

## Clean the build directory
rm -rf ${CURDIR}/rpmbuild
mkdir -p ${CURDIR}/rpmbuild/{BUILD,BUILDROOT,SRPMS,SOURCES,SPECS,RPMS,BUILDDEPS}
chmod a+w ${CURDIR}/rpmbuild/{BUILD,BUILDROOT,SRPMS,RPMS,BUILDDEPS}
[ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled && chcon -Rt container_file_t ${CURDIR}/rpmbuild

## Copy over the packaging files
cp ${RPMDIR}/SOURCES/* ${CURDIR}/rpmbuild/SOURCES
cp ${RPMDIR}/SPECS/tigervnc.spec ${CURDIR}/rpmbuild/SPECS
sed -i "s/@VERSION@/${VERSION}/" ${CURDIR}/rpmbuild/SPECS/tigervnc.spec
cp ${CURDIR}/builddeps/* ${CURDIR}/rpmbuild/BUILDDEPS

## Copy over the source code

(cd ${TOPDIR} && git archive --prefix tigervnc-${VERSION}/ HEAD) | bzip2 > ${CURDIR}/rpmbuild/SOURCES/tigervnc-${VERSION}.tar.bz2

## Start the build

docker run --volume ${CURDIR}/rpmbuild:/home/rpm/rpmbuild --volume ${CURDIR}/builddeps:/home/rpm/builddeps --interactive --tty --rm tigervnc/${DOCKER} \
	bash -c "
	sudo yum -y install ~/builddeps/*.rpm &&
	sudo yum-builddep -y ~/rpmbuild/SPECS/tigervnc.spec &&
	sudo chown 0.0 ~/rpmbuild/SOURCES/* &&
	sudo chown 0.0 ~/rpmbuild/SPECS/* &&
	sudo chown 0.0 ~/builddeps &&
	rpmbuild -ba ~/rpmbuild/SPECS/tigervnc.spec
	"
