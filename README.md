# OpenWRT-x86_64-Install

This is a turn key script to create an OpenWRT x86_64 bootable image for Legacy and EFI bootup. This installing has only been tested on Ubuntu 20.04, but there is no reason why it would not work on earlier releases.

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
	createOpenWrtInstant.sh

## Step 4:
	
### 4.1 List block devices
	
		lsblk -I 8 -d
		
		NAME MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
		sda    8:0    0 465.8G  0 disk 
		sdb    8:16   1 465.8G  0 disk 
	
### 4.2 Insert USB or mSATA drive
		
### 4.3 List block devices again
	
		NAME MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
		sda    8:0    0 465.8G  0 disk 
		sdb    8:16   1 465.8G  0 disk 
		sdc    8:32   1   7.5G  0 disk
		
###	Make note of the change
		
		sdc    8:32   1   7.5G  0 disk
		
		/dev/sdc


