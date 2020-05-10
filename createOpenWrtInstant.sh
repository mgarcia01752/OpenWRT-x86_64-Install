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
LOG_FILE_PATH=${OPENWRT_WD}/${LOG_FILE}

#Build Options
FRESH_INSTALL=""
MAKE_OPENWRT=""
DEV_BLOCK=""
BOOTLOADER_TYPE=""

				############
				#  Functions
				############

print_log () {
	
	string=$1
	
	if [ ! -d ${LOG_FILE_PATH} ]; then
		echo $string > ${LOG_FILE_PATH}
	else	
		echo $string >> ${LOG_FILE_PATH}
	fi
	
	echo $string
	
}
			
remove_openwrt_instance() {
	
	print_log "Removing previous OpenWRT directories instances"

	rm -rf 	${OPENWRT_WD}/openwrt/		\
				${OPENWRT_WD}/luci/			\
				${OPENWRT_WD}/telephony/ 	\
				${OPENWRT_WD}/packages/ &> /dev/null
}

pull_latest_openwrt_updates () {
	
	print_log "Pulling the latest updated from OpenWRT Git site"
	
	cd $OPENWRT_WD/openwrt
	git pull &> /dev/null

	cd $OPENWRT_WD/luci  
	git pull &> /dev/null

	cd $OPENWRT_WD/packages
	git pull &> /dev/null

	cd $OPENWRT_WD/telephony
	git pull &> /dev/null

	cd $OPENWRT_WD
}

create_local_openwrt_clone () {
	
	print_log "Cloning OpenWRT-main"
	git clone https://github.com/openwrt/openwrt.git &> /dev/null
	
	print_log "Cloning OpenWRT-packages"
	git clone https://github.com/openwrt/packages.git &> /dev/null
	
	print_log "Cloning OpenWRT-luci"
	git clone https://github.com/openwrt/luci.git &> /dev/null
	
	print_log "Cloning OpenWRT-telephony"
	git clone https://github.com/openwrt/telephony.git &> /dev/null
}

change_local_openwrt_branch () {
	
	cd $OPENWRT_WD/openwrt
	print_log "Checkout OpenWRT branch ${OPENWRT_WORKING_BRANCH_VER}"
	git checkout ${OPENWRT_WORKING_BRANCH_VER} &> /dev/null
	
	cd $OPENWRT_WD/packages
	print_log "Checkout OpenWRT-packages branch ${OPENWRT_WORKING_BRANCH_VER}"
	git checkout ${OPENWRT_WORKING_BRANCH_VER} &> /dev/null
	
	cd $OPENWRT_WD/luci
	print_log "Checkout OpenWRT-luci branch ${OPENWRT_WORKING_BRANCH_VER}"
	git checkout ${OPENWRT_WORKING_BRANCH_VER} &> /dev/null
	
	cd $OPENWRT_WD/telephony
	print_log "Checkout OpenWRT-telephony branch ${OPENWRT_WORKING_BRANCH_VER}"
	git checkout ${OPENWRT_WORKING_BRANCH_VER} &> /dev/null
	
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
	
	print_log "Updating local feeds"	
	$OPENWRT_WD/openwrt/scripts/feeds update -a &> /dev/null
	
	print_log "Installing local feeds"
	$OPENWRT_WD/openwrt/scripts/feeds install -a &> /dev/null
}

copy_x86_64_default_config () {
	cp config/${OPENWRT_DEFAULT_x86_64_CONFIG} openwrt/.config
}

build_openwrt () {
	cd ${OPENWRT_WD}/openwrt
	make defconfig &> /dev/null
	make -j10
}

format_block_device () {
	
	print_log "FDISK ${DEV_BLOCK}"
	printf "o\nn\n\n\n\n\nt\nc\nw\n" | sudo fdisk ${DEV_BLOCK} &> /dev/null
	
	print_log "Creating DOS partion on ${DEV_BLOCK}1"
	sudo mkdosfs ${DEV_BLOCK}1 &> /dev/null
	
}

copy_image_to_media () {
		
	format_block_device ${DEV_BLOCK}
	
	bt=""
	
	[ ${BOOTLOADER_TYPE} == "EFI" ] && {
		print_log "EFI image selected"
		bt="-efi"		
	}
	
	###################################################
	# EFI -> openwrt-x86-64-generic-ext4-combined-efi.img.gz
	# LEG -> openwrt-x86-64-generic-ext4-combined.img.gz
	###################################################
	img="openwrt-x86-64-generic-ext4-combined${bt}.img.gz"
		
	file="${OPENWRT_WD}/openwrt/images/${img}"
	
	gzip -dc $file &> /dev/null | sudo dd of="${DEV_BLOCK}" bs=1M status=progress && sync &> /dev/null
	
}

prep_openwrt_branch_feeds_config () {
	change_local_openwrt_branch $OPENWRT_WORKING_BRANCH_VER
	create_local_openwrt_feeds_config
	update_local_openwrt_feeds_packages
	copy_x86_64_default_config
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
	printf "\t-c [LEGACY|EFI] <DEV_BLOCK>\tCreate bootable media\tExample: -c EFI /dev/sdb\n"
	printf "\t-h\t\t\t\tPrint usage and exit\n"
	printf "\t-v\t\t\t\tPrint version and exit\n"
	printf "\n\n\n"
}

							########
							#  MAIN
							########

while getopts ":b:c:frmv" OPTION; do
	case $OPTION in
	
		b) 
			OPENWRT_WORKING_BRANCH_VER="$OPTARG"
			print_log "OpenWRT branch selected:  $OPENWRT_WORKING_BRANCH_VER"
			;;
			
		f) 
			FRESH_INSTALL=${TRUE}
			;;
			
		r)
			remove_openwrt_instance
			exit
			;;
			
		m)
			MAKE_OPENWRT=${TRUE}
			;;
			
		v) 
			echo "Version: ${VERSION}"
			exit
			;;

		c) 
			eval "BOOTLOADER_TYPE=\${$((OPTIND-1))}"
			eval "DEV_BLOCK=\${$((OPTIND))}"
			
			[ ${OPTARG} != "EFI" ] && [ ${OPTARG} != "LEGACY" ]  && {
				usage
				exit
			}	
			;;
	
		?|h)
			usage
			exit
			;;
			
	esac
done
shift $((OPTIND-1))

[  -n "${FRESH_INSTALL}"  ] || [ ! -d "openwrt" ] && {
	
	[ -d "openwrt" ] && {
		print_log "Removing all OpenWRT directories"
		remove_openwrt_instance	
	}

	print_log "Cloning OpenWRT ${OPENWRT_WORKING_BRANCH_VER} Branch"
	create_local_openwrt_clone;
	
	prep_openwrt_branch_feeds_config;

}

[ -d "openwrt" ]  &&  [  ! -n "${FRESH_INSTALL}"  ] && {
	
	print_log "Updating existing OpenWRT repository from Git Site"	
	pull_latest_openwrt_updates
	
	prep_openwrt_branch_feeds_config;
	
}

# Build image if selected
[ "${MAKE_OPENWRT}" == "${TRUE}" ] &&  {
	
	print_log "Building OpenWRT Images"
	build_openwrt
	
	#Create directory if it does not exist
	[ ! -d "${OPENWRT_WD}/openwrt/images" ] && {
		print_log "Creating image directoy for x86-64 EFI and Legacy images"
		mkdir ${OPENWRT_WD}/openwrt/images 
	}
	
	#Copy images to image directory
	print_log "Coping OpenWRT images to ${OPENWRT_WD}/openwrt/images"
	cp ${OPENWRT_WD}/openwrt/bin/targets/x86/64/*.gz ${OPENWRT_WD}/openwrt/images &> /dev/null
	
 }
 
 #Make sure creating image is selected and images directoy is present
 [ "${BOOTLOADER_TYPE}" != "" ] && [ "${DEV_BLOCK}" != "" ] && [ -d "${OPENWRT_WD}/openwrt/images" ]  && {
	print_log "Creating bootable media on ${DEV_BLOCK}"
	copy_image_to_media	
 }
 
 
 
 
 
