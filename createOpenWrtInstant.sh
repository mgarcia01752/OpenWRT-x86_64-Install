#!/bin/bash

#########################################################################
# Copyright 2020 Maurice Garcia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
########################################################################

TRUE=1;
FALSE=0;

VERSION="1.0.0"

OPENWRT_DEFAULT_BRANCH="master"
OPENWRT_WORKING_BRANCH_VER=${OPENWRT_DEFAULT_BRANCH}
OPENWRT_DEFAULT_x86_64_CONFIG="_.config-x86_64-base-configuration"
OPENWRT_WD=$PWD

EPOCH=`date +%s`
LOG_FILE="openwrt_build_log-${EPOCH}.log"

#Build Options
FRESH_INSTALL=""
MAKE_OPENWRT=""
MEDIA_TYPE=""
BOOT_TYPE=""

				############
				#  Functions
				############

print_log () {
	
	string=$1
	
	if [ ! -d ${LOG_FILE} ]; then
		echo $string >> ${LOG_FILE}
	else	
		echo $string >> ${LOG_FILE}
	fi
	
}
			
remove_openwrt_instance() {
	
	print_log "Removing previous OpenWRT directories instances"

	rm -rf 	${OPENWRT_WD}/openwrt/		\
				${OPENWRT_WD}/luci/ 				\
				${OPENWRT_WD}/telephony/ 	\
				${OPENWRT_WD}/packages/
}

pull_latest_openwrt_updates () {
	
	print_log "Pulling the latest updated from OpenWRT Git site"
	
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
	
	print_log "Cloning OpenWRT"
	git clone https://github.com/openwrt/openwrt.git
	
	print_log "Cloning OpenWRT-packages"
	git clone https://github.com/openwrt/packages.git
	
	print_log "Cloning OpenWRT-luci"
	git clone https://github.com/openwrt/luci.git
	
	print_log "Cloning OpenWRT-telephony"
	git clone https://github.com/openwrt/telephony.git
}

change_local_openwrt_branch () {
	
	cd $OPENWRT_WD/openwrt
	print_log "Checkout OpenWRT branch ${OPENWRT_WORKING_BRANCH_VER}"
	git checkout ${OPENWRT_WORKING_BRANCH_VER}
	
	cd $OPENWRT_WD/packages
	print_log "Checkout OpenWRT-packages branch ${OPENWRT_WORKING_BRANCH_VER}"
	git checkout ${OPENWRT_WORKING_BRANCH_VER}
	
	cd $OPENWRT_WD/luci
	print_log "Checkout OpenWRT-luci branch ${OPENWRT_WORKING_BRANCH_VER}"
	git checkout ${OPENWRT_WORKING_BRANCH_VER}
	
	cd $OPENWRT_WD/telephony
	print_log "Checkout OpenWRT-telephony branch ${OPENWRT_WORKING_BRANCH_VER}"
	git checkout ${OPENWRT_WORKING_BRANCH_VER}
	
	cd $OPENWRT_WD
}

create_local_openwrt_feeds_config () {
	
	print_log "Creating local feeds.conf file"
	
	FEEDS_FILE="$OPENWRT_WD/openwrt/feeds.conf"

	echo "src-link packages $OPENWRT_WD/packages" > $FEEDS_FILE
	echo "src-link luci $OPENWRT_WD/luci" >> $FEEDS_FILE
	echo "src-link routing $OPENWRT_WD/routing" >> $FEEDS_FILE
	echo "src-link telephony $OPENWRT_WD/telephony" >> $FEEDS_FILE

}

update_local_openwrt_feeds_packages () {
	
	print_log "Updating and installing feeds"
	
	$OPENWRT_WD/openwrt/scripts/feeds update -a
	$OPENWRT_WD/openwrt/scripts/feeds install -a
}

copy_x86_64_default_config () {
	cp config/${OPENWRT_DEFAULT_x86_64_CONFIG} openwrt/.config
}

build_openwrt () {
	cd ${OPENWRT_WD}/openwrt
	make defconfig
	make -j10
}

format_block_device () {
	printf "o\nn\n\n\n\n\nt\nc\nw\n" | sudo fdisk /dev/${1}
	sudo mkdosfs /dev/${1}1
}

copy_image_to_media () {
	
	boot_type=$1
	block_device=$2
	
	format_block_device ${block_device}
	
	bt=""
	
	[ ${boot_type} == "EFI" ] && { 
		bt="-efi"		
	}
	
	img="openwrt-x86-64-generic-ext4-combined${bt}.img.gz"
		
	file="${OPENWRT_WD}/openwrt/bin/target/x86/64/${img}"
	
	gzip -dc $file | sudo dd of="/dev/${MEDIA_TYPE}" bs=1M status=progress && sync
	
}

usage () {
	echo
	echo "OpenWRT x86-64 Installation"
	echo 
	echo "Version: ${VERSION}"
	echo
	echo "Usage:"
	printf "\t-f \t\t\t\tFresh Install, Remove previous installation\n"
	printf "\t-b [${OPENWRT_DEFAULT_BRANCH}]\t\t\tOpenWRT install branch\n"
	printf "\t-r\t\t\t\tRemove OpenWRT directories, then exit\n"
	printf "\t-m\t\t\t\tBuild OpenWRT\n"
	printf "\t-c [LEGACY|EFI] <media_type>\tLocation: /dev/<medial_type>\n"	
	printf "\n\n\n"
}

							########
							#  MAIN
							########

while getopts ":b:c:frmv" OPTION; do
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
			
		v) 
			echo ${VERSION}
			exit
			;;

		c) 
			BOOT_TYPE="$OPTARG";shift
			MEDIA_TYPE="$OPTARG";shift
			copy_image_to_media $BOOT_TYPE $MEDIA_TYPE
			exit
			;;
	
		?|h)
			usage
			exit
			;;
			
	esac
done
shift $((OPTIND-1))

if [  -n "${FRESH_INSTALL}"  ] || [ ! -d "openwrt" ]; then
	
	[ -d "openwrt" ] && {
		print_log "Removing all OpenWRT directories"
		remove_openwrt_instance	
	}

	print_log "Cloning OpenWRT ${OPENWRT_WORKING_BRANCH_VER} Branch"
	create_local_openwrt_clone

fi

[ -d "openwrt" ]  &&  [  ! -n "${FRESH_INSTALL}"  ] && {
	echo "Updating existing OpenWRT repository from Git Site"	
	pull_latest_openwrt_updates
}

change_local_openwrt_branch $OPENWRT_WORKING_BRANCH_VER

create_local_openwrt_feeds_config

update_local_openwrt_feeds_packages

copy_x86_64_default_config

# Build image if selected
[ "${MAKE_OPENWRT}" == "${TRUE}" ] &&  {
	
	print_log "Building OpenWRT Images"
	build_openwrt
	
	#Create directory if it does not exist
	[ ! -d ${OPENWRT_WD}/openwrt/images ] && {
		print_log "Creating image directoy for x86-64 EFI and Legacy images"
		mkdir ${OPENWRT_WD}/openwrt/images 
	}
	
	#Copy images to image directory
	print_log "Coping OpenWRT images to ${OPENWRT_WD}/openwrt/images"
	cp ${OPENWRT_WD}/openwrt/bin/targets/x86/64/*.gz ${OPENWRT_WD}/openwrt/images
	
 }
