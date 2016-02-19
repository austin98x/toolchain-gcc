#!/bin/bash

set -e

###############################################################################
#
# common functions
#
function package_dir()
{
	package=$1
	suffix=$2

	dir=${package%$suffix}
	echo $dir
}

function prepare_package()
{
	package=$1
	url=$2

	if [ ! -e $package ] ; then
		wget $url/$package
	fi

	echo "Extracting $package ..."
	tar xf $package
}

function build_and_install()
{
	make -j`nproc`
	make install
}

function print_ignore_build_msg()
{
	package=$1
	echo "Ignoring build: $package"
}

function mark_build_succeeded()
{
	touch .succeeded
}
#
###############################################################################
#
# binutils
#
function build_binutils()
{
	_VER=$_BINUTILS_VER
	_PACKAGE=binutils-${_VER}.tar.bz2

	dir=`package_dir ${_PACKAGE} .tar.bz2`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg binutils
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} https://ftp.gnu.org/gnu/binutils

	cd $dir
	./configure	\
			--prefix=${_HOST_DIR}/usr	\
			--with-sysroot=${_SYSROOT}	\
			--target=${_TARGET}	\
			--enable-threads	\
			--disable-shared	\
			--enable-static	\
			--disable-multilib	\
			--disable-werror

	build_and_install
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# m4
#
function build_m4()
{
	_VER=$_M4_VER
	_PACKAGE=m4-${_VER}.tar.xz

	dir=`package_dir ${_PACKAGE} .tar.xz`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg m4
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} http://ftp.gnu.org/gnu/m4

	cd $dir
	./configure	\
			--prefix=${_HOST_DIR}/usr

	build_and_install
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# gmp
#
function build_gmp()
{
	_VER=$_GMP_VER
	_PACKAGE=gmp-${_VER}.tar.xz

	dir=`package_dir ${_PACKAGE} a.tar.xz`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg gmp
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} https://ftp.gnu.org/gnu/gmp

	cd $dir
	./configure	\
			--prefix=${_HOST_DIR}/usr	\
			--enable-shared

	build_and_install
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# mpfr
#
function build_mpfr()
{
	_VER=$_MPFR_VER
	_PACKAGE=mpfr-${_VER}.tar.xz

	dir=`package_dir ${_PACKAGE} .tar.xz`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg mpfr
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} https://ftp.gnu.org/gnu/mpfr

	cd $dir
	./configure	\
			--prefix=${_HOST_DIR}/usr	\
			--with-gmp=${_HOST_DIR}/usr	\
			--enable-shared

	build_and_install
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# mpc
#
function build_mpc()
{
	_VER=$_MPC_VER
	_PACKAGE=mpc-${_VER}.tar.gz

	dir=`package_dir ${_PACKAGE} .tar.gz`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg mpc
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} https://ftp.gnu.org/gnu/mpc

	cd $dir
	./configure	\
			--prefix=${_HOST_DIR}/usr	\
			--with-gmp=${_HOST_DIR}/usr	\
			--enable-shared

	build_and_install
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# gcc
#
function build_gcc()
{
	# initial, intermediate, final
	step=$1
	_VER=$_GCC_VER
	_PACKAGE=gcc-${_VER}.tar.bz2

	_COMMON_CFG="--prefix=${_HOST_DIR}/usr	\
			--with-sysroot=${_SYSROOT}	\
			--target=${_TARGET}	\
			--with-gmp=${_HOST_DIR}/usr	\
			--with-mpfr=${_HOST_DIR}/usr	\
			--with-mpc=${_HOST_DIR}/usr	\
			--enable-threads=posix	\
			--disable-libsanitizer  \
			--disable-libquadmath \
			--enable-gnu-unique-object	\
			--disable-multilib"

	_EXTRA_CFG=""
	_MAKE_ARGS=""
	_MAKE_INSTALL_ARGS=""

	dir=`package_dir ${_PACKAGE} .tar.bz2`

	if [ -f "$dir/build-$step/.succeeded" ] ; then
		print_ignore_build_msg gcc-$step
		return
	fi

	if [ ! -d "$dir" ] ; then
		prepare_package ${_PACKAGE} https://ftp.gnu.org/gnu/gcc/gcc-${_VER}
	fi

	mkdir $dir/build-$step
	cd $dir/build-$step

	case $step in
		initial)
			_EXTRA_CFG="\
				--enable-languages=c	\
				--disable-shared	\
				--disable-libgcc	\
				--without-headers	\
				--with-newlib	\
				"
			_MAKE_ARGS="all-gcc"
			_MAKE_INSTALL_ARGS="install-gcc"
			;;
		intermediate)
			_EXTRA_CFG="\
				--enable-languages=c	\
				--enable-shared	\
				"
			_MAKE_ARGS="all-gcc all-target-libgcc"
			_MAKE_INSTALL_ARGS="install-gcc install-target-libgcc"
			;;
		final)
			_EXTRA_CFG="\
				--enable-languages=c,c++	\
				--enable-shared	\
				--with-build-time-tools=${_HOST_DIR}/usr/${_TARGET}/bin	\
				"
			_MAKE_INSTALL_ARGS="install"
			;;
		*)
			echo "Unkown build step: $step"
			exit 1
			;;
	esac

	../configure	\
			${_COMMON_CFG}	\
			${_EXTRA_CFG}

	make -j`nproc` ${_MAKE_ARGS}
	make -j`nproc` ${_MAKE_INSTALL_ARGS}
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# linux headers
#
function build_linux_headers()
{
	_VER=$_HEADER_VER
	_PACKAGE=linux-${_VER}.tar.xz

	dir=`package_dir ${_PACKAGE} .tar.xz`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg headers
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} https://www.kernel.org/pub/linux/kernel/v3.x

	cd $dir
	make -j`nproc` ARCH=arm64 INSTALL_HDR_PATH=${_SYSROOT}/usr headers_install
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# gawk
#
function build_gawk()
{
	_VER=$_GAWK_VER
	_PACKAGE=gawk-${_VER}.tar.xz

	dir=`package_dir ${_PACKAGE} .tar.xz`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg gawk
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} http://ftp.gnu.org/gnu/gawk

	cd $dir
	./configure	\
			--prefix=${_HOST_DIR}/usr

	build_and_install
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# glibc
#
function build_glibc()
{
	# base, full
	step=$1

	_VER=$_GLIBC_VER
	_PACKAGE=glibc-${_VER}.tar.xz

	dir=`package_dir ${_PACKAGE} .tar.xz`

	if [ -f "$dir/build-$step/.succeeded" ] ; then
		print_ignore_build_msg glibc-$step
		return
	fi

	if [ ! -d "$dir" ] ; then
		prepare_package ${_PACKAGE} http://ftp.gnu.org/gnu/glibc
	fi

	mkdir $dir/build-$step
	cd $dir/build-$step

	export CC="${_HOST_DIR}/usr/bin/${_TARGET}-gcc"
	export CXX="${_HOST_DIR}/usr/bin/${_TARGET}-g++"
	export CFLAGS="-O2"
	export CXXFLAGS="-O2"

	# Fixed make version >= 4.0
	sed -ie "/3\.79\*.*/s/)/ \| 4\.\*)/" ../configure

	../configure	\
			libc_cv_forced_unwind=yes	\
			libc_cv_ssp=no	\
			--prefix=/usr	\
			--target=${_TARGET}	\
			--host=${_TARGET}	\
			--with-headers=${_SYSROOT}/usr/include	\
			--with-fp	\
			--without-cvs	\
			--without-gd	\
			--enable-obsolete-rpc	\
			--enable-shared	\
			--disable-profile

	case $step in
		base)
			sed -ie "s/\(^headers.*$\)/\1 bits\/stdio_lim.h/" ../stdio-common/Makefile

			make -j`nproc`	\
				install_root=${_SYSROOT}	\
				install-bootstrap-headers=yes	\
		 		install-headers

				make -j`nproc` csu/subdir_lib

				# Hard code workaround for building gcc intermediate
				mkdir -p ${_SYSROOT}/usr/lib
				cp csu/crt{1,i,n}.o ${_SYSROOT}/usr/lib/

				mkdir -p ${_SYSROOT}/usr/include/gnu
				touch ${_SYSROOT}/usr/include/gnu/stubs.h

				${_HOST_DIR}/usr/bin/${_TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${_SYSROOT}/usr/lib/libc.so
			;;
		full)
			make -j`nproc`
			make install_root=${_SYSROOT} install
			;;
		*)
			echo "Unkown build step: $step"
			exit 1
			;;
	esac

	unset CC CXX CFLAGS CXXFLAGS
	mark_build_succeeded
	cd -
}
#
###############################################################################
#
# gdb
#
function build_gdb()
{
	_VER=$_GDB_VER
	_PACKAGE=gdb-${_VER}.tar.bz2

	dir=`package_dir ${_PACKAGE} .tar.bz2`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg gdb
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} http://ftp.gnu.org/gnu/gdb

	cd $dir
	./configure	\
			--prefix=${_HOST_DIR}/usr	\
			--target=${_TARGET}	\
			--enable-threads	\
			--without-uiout	\
			--without-guile \
			--without-babeltrace \
			--disable-tui	\
			--disable-gdbtk	\
			--disable-werror	\
			--with-python=`which python2`

	build_and_install
	mark_build_succeeded
	cd -
}
###############################################################################
#
# usage
#
function usage()
{
	echo "Usage: $1 [options]"
	echo "Options:"
	echo "-i                target abi, [lp64]"
	echo "-a                target arch, [armv8-a]"
	echo "-t                target, [aarch64-unknown-linux-gnu]"
	echo "-h                host directory, [/opt/toolchain/host]"
	echo "-d                build with gdb"
}
#
###############################################################################
#
# ln -s everything ${_TARGET}-* to /usr/local/bin
#
function do_link()
{
	files=`ls ${_HOST_DIR}/usr/bin/${_TARGET}-*`

	for file in $files ; do
		name=`basename $file`
		ln -fs "$file" /usr/local/bin/$name
	done
}
#
###############################################################################
#
# work start from here
#
_TARGET=aarch64-unknown-linux-gnu
_HOST_DIR=/opt/toolchain/host

_GAWK_VER=4.1.3
_BINUTILS_VER=2.24
_M4_VER=1.4.17
_GMP_VER=6.0.0a
_MPFR_VER=3.1.3
_MPC_VER=1.0.3
_GCC_VER=4.9.3
_HEADER_VER=3.14.1
_GLIBC_VER=2.19
_GDB_VER=7.7.1

_ABI="lp64" #ilp32/lp64
_ARCH="armv8-a" #armv8-a/armv8.1-a
_WITH_GDB=1

while getopts i:a:t:h:d flag; do
	case $flag in
		i)
			_ABI=$OPTARG
			;;
		a)
			_ARCH=$OPTARG
			;;
		h)
			_HOST_DIR=$OPTARG
			;;
		d)
			_WITH_GDB=1
			;;
		*)
			usage $0
			exit 0;
			;;
	esac
done

_SYSROOT=${_HOST_DIR}/usr/${_TARGET}/sysroot

export LDFLAGS="-L${_HOST_DIR}/lib -L${_HOST_DIR}/usr/lib -Wl,-rpath,${_HOST_DIR}/usr/lib"
export PATH="${_HOST_DIR}/bin:${_HOST_DIR}/usr/bin:$PATH"

build_gawk
build_binutils
build_m4
build_gmp
build_mpfr
build_mpc
build_gcc initial
build_linux_headers
build_glibc base
build_gcc intermediate
build_glibc full
build_gcc final

if [ "${_WITH_GDB}" = "1" ]; then
	build_gdb
fi

do_link
#
###############################################################################
#
# vim: ts=4 noet ci pi sts=0 sw=4
