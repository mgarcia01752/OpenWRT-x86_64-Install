# OpenWRT-x86_64-Install

This is a turn key script to create an OpenWRT x86_64 bootable image for Legacy and EFI bootup. This installing has only been tested on Ubuntu 20.04, but there is no reason why it would not work on earlier releases.


		OpenWRT x86-64 Installation

		Version: 1.0.0

		Usage:
			-b [master]			OpenWRT install branch
			-c [LEGACY|EFI] <DEV_BLOCK>	Create bootable media	Example: -c EFI /dev/sdb
			-f 				Fresh Install, Remove previous installation
			-i  				Ignore Warning and Error Suppresion
			-r				Remove OpenWRT directories, then exit
			-m				Build OpenWRT
			-h				Print usage and exit
			-v				Print version and exit


## Usage

### Install OpenWRT master branch

		createOpenWrtInstant.sh

### Install OpenWRT master branch and build image

		createOpenWrtInstant.sh -m

### Install OpenWRT master branch, build image and create bootable ext4-fs image on media

		createOpenWrtInstant.sh -m -c EFI /dev/sdb
		
### Reinstall OpenWRT master branch when there is an existing OpenWRT

		createOpenWrtInstant.sh -f

## Manual steps to prepare installation

## Step 1:

  Copy and Paste the following and make sure that each of the required packages are installed. You may need to run this a couple of times.

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


## Step 2:

	git clone https://github.com/mgarcia01752/OpenWRT-x86_64-Install.git


## Step 3:

  This step will: 
  	
  	1. Clone and create the required OpenWRT directories.
  	2. Create a feeds.conf file that is needed to point the required packages to the local computer
  	3. Copy a base x86_64 configuration file that is needed to setup the gcc toolchain for compiling

  Copy/Paste the following:
  
	cd OpenWRT-x86_64-Install
	createOpenWrtInstant.sh -m
	
  At this point, you will have an image to manually install on whatever media you prefer. Steps 4 and 5 will provide some guadiance.
	
  You can use -c option to have the script install the image for you. Make sure you select the correct media device. 

## Step 4: Copy image onto media

  ./installOpenWrt2Media.sh -h
  
  
	OpenWRT - Copy x86_64 image to media

	Version: 1.0.0

	Usage:
		-m <Device Block>		Media or Device Block	Example: -m /dev/sdb
		-b [LEGACY]|EFI			Create bootable media	Example: -b EFI
		-h				Print usage and exit
		-v				Print version and exit
		
   ./installOpenWrt2Media.sh -m /dev/sdb -b LEGACY



		
		
