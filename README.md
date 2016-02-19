# toolchain-gcc

This is script for build GCC on Linux platform.

## Usage

Download this script.

Give the script execution permissions.

build-gcc-x86:
	This is for x86 platform. Support i386, i586, i686, x86_64.
	If you want to use special version of GCC, you should modify ${_GCC_VER} value.(default is 5.3.0)

build-gcc-mips:
	This if for MIPS platform. Default is mips32.
	If you want to use special version of GCC, you should modify ${_GCC_VER} value.(default is 4.9.3)

build-gcc-arm:
	This if for ARM platform. Default is aarch64.
	If you want to use special version of GCC, you should modify ${_GCC_VER} value.(default is 4.9.3)

## Easy commands

        ./build-gcc-x86.sh -p $PWD/
