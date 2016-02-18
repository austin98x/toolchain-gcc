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

function uninstall()
{
	rm -rf $PREFIX/usr/include/gmp.h
	rm -rf $PREFIX/usr/include/mpc.h
	rm -rf $PREFIX/usr/include/mpf2mpfr.h
	rm -rf $PREFIX/usr/include/mpfr.h
	rm -rf $PREFIX/usr/lib/libgmp*
	rm -rf $PREFIX/usr/lib/libmpc*
	rm -rf $PREFIX/usr/lib/libmpfr*
	rm -rf $PREFIX/usr/share/doc/mpfr
	rm -rf $PREFIX/usr/share/info/gmp*
	rm -rf $PREFIX/usr/share/info/mpc*
	rm -rf $PREFIX/usr/share/info/mpfr*
	rm -rf $PREFIX/usr/share/info/dir
}
#
###############################################################################
#
# gmp
#
function build_gmp()
{
	_VER=${_GMP_VER}
	_PACKAGE=gmp-${_VER}.tar.xz

	dir=`package_dir ${_PACKAGE} .tar.xz`

	if [ -f "$dir/.succeeded" ] ; then
		print_ignore_build_msg gmp
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} https://ftp.gnu.org/gnu/gmp

	cd $dir

	./configure	\
			--prefix=${PREFIX}/usr	\
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
	_VER=${_MPFR_VER}
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
			--prefix=${PREFIX}/usr	\
			--with-gmp=${PREFIX}/usr	\
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
	_VER=${_MPC_VER}
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
			--prefix=${PREFIX}/usr	\
			--with-gmp=${PREFIX}/usr	\
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
	_VER=${_GCC_VER}
	_PACKAGE=gcc-${_VER}.tar.bz2

	_COMMON_CFG="--prefix=${PREFIX}/usr	\
			--with-gmp=${PREFIX}/usr	\
			--with-mpfr=${PREFIX}/usr	\
			--with-mpc=${PREFIX}/usr"

	_EXTRA_CFG=""
	_MAKE_ARGS=""
	_MAKE_INSTALL_ARGS=""

	dir=`package_dir ${_PACKAGE} .tar.bz2`

	if [ -f "$dir/build-${step}/.succeeded" ] ; then
		print_ignore_build_msg gcc-${step}
		return
	fi

	rm -fr $dir
	prepare_package ${_PACKAGE} https://ftp.gnu.org/gnu/gcc/gcc-${_VER}

	mkdir $dir/build-${step}
	cd $dir/build-${step}

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

###############################################################################
#
# usage
#
function usage()
{
	echo "Usage: $1 [options]"
	echo "[-p prefix] custom prefix"
	echo "[-u] uninstall gcc"
}
#
###############################################################################
#
# ln -s everything * to /usr/local/bin
#
function do_link()
{
	files=`ls ${PREFIX}/usr/bin/${_TARGET}-*`

	for file in $files ; do
		name=`basename $file | sed 's/unknown-linux-gnu/linux/g'`
		ln -fs "$file" /usr/local/bin/$name
	done
}
#
###############################################################################
#
# work start from here
#

PREFIX=
_GMP_VER=6.1.0
_MPFR_VER=3.1.3
_MPC_VER=1.0.3
_GCC_VER=5.3.0

while getopts p:u flag; do
	case $flag in
		p)
			PREFIX=$OPTARG
			;;
		u)
			uninstall
			exit 0
			;;
		*)
			usage $0
			exit 0;
			;;
	esac
done

build_gmp
build_mpfr
build_mpc
build_gcc initial
build_gcc intermediate
build_gcc final

#do_link

#
###############################################################################
#
# vim: ts=4 noet ci pi sts=0 sw=4
