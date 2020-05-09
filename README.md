# OpenWRT-x86_64-Install

This is a turn key script to create an OpenWRT x86_64 bootable image for Legacy and EFI bootup. This installing has only been tested on Ubuntu 20.04, but there is no reason why it would not work on earlier releases.

## Step 1:

git clone https://github.com/mgarcia01752/OpenWRT-x86_64-Install.git

## Step 2:

  Copy and Paste the following and make sure that each of the required packages are installed

	sudo apt-get install git
	sudo apt-get install make
	sudo apt-get install gcc
	sudo apt-get install binutils
	sudo apt-get install bzip2
	sudo apt-get install flex
	sudo apt-get install python
	sudo apt-get install python3.5+
	sudo apt-get install python2-doc python-tk python2.7-doc binfmt-support
	sudo apt-get install libpython2-stdlib libpython2.7-minimal libpython2.7-stdlib python-is-python2 python2 python2-minimal python2.7 python2.7-minimal
	sudo apt-get install perl
	sudo apt-get install grep
	sudo apt-get install diffutils
	sudo apt-get install unzip
	sudo apt-get install getopt
	sudo apt-get install subversion
	sudo apt-get install libz-dev
	sudo apt-get install libc
	sudo apt-get install g++
	sudo apt-get install gawk
	sudo apt-get install zlib1g libncurses5 g++ flex
	sudo apt-get install build-essential libncurses5 zlib1g flex
	sudo apt-get install libncurses-dev

## Step 3:

run: createOpenWrtInstant.sh




