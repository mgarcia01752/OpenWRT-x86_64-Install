#!/bin/bash

TRUE=1;
FALSE=0;

OPENWRT_DEFAULT_BRANCH="master"
OPENWRT_WORKING_BRANCH_VER=${OPENWRT_DEFAULT_BRANCH}
OPENWRT_DEFAULT_x86_64_CONFIG="_.config-default-x86_64"
OPENWRT_WD=$PWD

FRESH_INSTALL=FALSE;



				############
				#	Functions	#
				############
				
remove_openwrt_instance() {
  rm -rf openwrt/ luci/ telephony/ packages/
}

prepare_openwrt_installation () {
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
}

pull_latest_openwrt_updates () {

  cd $OPENWRT_WD/openwrt
  git pull

  cd $OPENWRT_WD/luci  
  git pull
  
  cd $OPENWRT_WD/packages
  git pull
  
  cd $OPENWRT_WD/telephony
  git pull
  
  cd $OPENWRT_WD
}

create_local_openwrt_clone () {
  git clone https://github.com/openwrt/openwrt.git
  git clone https://github.com/openwrt/packages.git
  git clone https://github.com/openwrt/luci.git
  git clone https://github.com/openwrt/telephony.git
}

change_local_openwrt_branch () {
	
  cd $OPENWRT_WD/openwrt
  git checkout $1
	
  cd $OPENWRT_WD/packages
  git checkout $1
	
  cd $OPENWRT_WD/luci
  git checkout $1
	
  cd $OPENWRT_WD/telephony
  git checkout $1
	
  cd $OPENWRT_WD
}

create_local_openwrt_feeds_config () {
  
  FEEDS_FILE="$OPENWRT_WD/openwrt/feeds.conf"
  
  echo "src-link packages $OPENWRT_WD/packages" > $FEEDS_FILE
  echo "src-link luci $OPENWRT_WD/luci" >> $FEEDS_FILE
  echo "src-link routing $OPENWRT_WD/routing" >> $FEEDS_FILE
  echo "src-link telephony $OPENWRT_WD/telephony" >> $FEEDS_FILE

}

update_local_openwrt_feeds_packages () {
  $OPENWRT_WD/openwrt/scripts/feeds update -a
  $OPENWRT_WD/openwrt/scripts/feeds install -a
}

usage () {

	echo
	echo "OpenWRT x86-64 Installation"
	echo
	echo "Usage:"
	printf "\t-f, --fresh\t\tFresh Install, Remove previous installation\n"
	printf "\t-b, --branch [${OPENWRT_DEFAULT_BRANCH}]\tOpenWRT install branch\n"
	printf "\t-r, --remove\t\tRemove OpenWRT directories, then exit\n"
	print "\t-make\t\tBuild OpenWRT\n"
	printf "\n\n\n"
}

copy_x86_64_default_config () {
	cp config/_.config-x86_64-base-configuration openwrt/
}

build_openwrt () {
	cd ${OPENWRT_WD}/openwrt
	
	make defconfig
	
	make -j10
}

							########
							#	MAIN	#
							########

while getopts "b:frm" OPTION; do
    case $OPTION in
	
        b)
			OPENWRT_WORKING_BRANCH_VER="$OPTARG"
			echo "OpenWRT branch selected:  $OPENWRT_WORKING_BRANCH_VER"
            ;;
			
        f)
			FRESH_INSTALL=${TRUE}
            ;;
			
		r)
			remove_openwrt_instance
			exit;			
            ;;
			
		m)
			MAKE_OPENWRT=${TRUE}
			;;
			
        ?)
            usage
			exit
            ;;
    esac
done
shift $((OPTIND-1))

if [ -n "${FRESH_INSTALL}" ]; then
	
	echo "Removing all openWRT directories"
	remove_openwrt_instance
	
	echo "Cloning OpenWRT ${OPENWRT_WORKING_BRANCH_VER} Branch"
	create_local_openwrt_clone

fi

if [ -d "openwrt" ] && [ ! -n "${FRESH_INSTALL}" ]; then

	echo "Updating existing OpenWRT repository from Git Site"	
	pull_latest_openwrt_updates

fi

change_local_openwrt_branch $OPENWRT_WORKING_BRANCH_VER

create_local_openwrt_feeds_config

update_local_openwrt_feeds_packages

copy_x86_64_default_config

if [ -n ${MAKE_OPENWRT} ]; then
	build_openwrt
fi


