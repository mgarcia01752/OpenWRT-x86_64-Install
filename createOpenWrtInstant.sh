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

LOG_FILE_PATH="${OPENWRT_WD}/log"
LOG_FILE="${LOG_FILE_PATH}/build_log-${EPOCH}.log"

#Build Options
FRESH_INSTALL=""
MAKE_OPENWRT=""
DEV_BLOCK=""
BOOTLOADER_TYPE=""
STDOUT_REDIRECT=" &> /dev/null"

				############
				#  Functions
				############

cmd () {	
	_cmd="$1 ${STDOUT_REDIRECT}"
	eval ${_cmd}
}

init () {

	# Create log directory if it does not exist
	[ ! -d log ] && {
		mkdir ${LOG_FILE_PATH}
	}
	

}

check_github_connection () {
	
	status=${FALSE}
	
	[ ping https://github.com ] && {
		status=${TRUE}
	}
	
	echo ${status}
}

print_log () {
	
	string=$1
	
	time_stamp="[`date +%m-%d-%Y-%T`]"
	
	echo "${time_stamp} $string" >> ${LOG_FILE}
	
	printf "${time_stamp} ${string}\n"
	
}
			
remove_openwrt_instance() {
	
	print_log "Removing previous OpenWRT directories instances"

	cmd "rm -rf 	${OPENWRT_WD}/openwrt/		\
				${OPENWRT_WD}/luci/			\
				${OPENWRT_WD}/telephony/ 	\
				${OPENWRT_WD}/packages/"

}

pull_latest_openwrt_updates () {
	
	print_log "Pulling the latest updated from OpenWRT Git site"
	
	cd $OPENWRT_WD/openwrt
	cmd "git pull"

	cd $OPENWRT_WD/luci  
	cmd "git pull"

	cd $OPENWRT_WD/packages
	cmd "git pull"

	cd $OPENWRT_WD/telephony
	cmd "git pull"

	cd $OPENWRT_WD
}

create_local_openwrt_clone () {
	
	print_log "Cloning OpenWRT-main"
	cmd "git clone https://github.com/openwrt/openwrt.git"
	
	print_log "Cloning OpenWRT-packages"
	cmd "git clone https://github.com/openwrt/packages.git"
	
	print_log "Cloning OpenWRT-luci"
	cmd "git clone https://github.com/openwrt/luci.git"
	
	print_log "Cloning OpenWRT-telephony"
	cmd "git clone https://github.com/openwrt/telephony.git"
}

change_local_openwrt_branch () {
	
	cd $OPENWRT_WD/openwrt
	print_log "Checkout OpenWRT branch ${OPENWRT_WORKING_BRANCH_VER}"
	cmd "git checkout ${OPENWRT_WORKING_BRANCH_VER}"
	
	cd $OPENWRT_WD/packages
	print_log "Checkout OpenWRT-packages branch ${OPENWRT_WORKING_BRANCH_VER}"
	cmd "git checkout ${OPENWRT_WORKING_BRANCH_VER}"
	
	cd $OPENWRT_WD/luci
	print_log "Checkout OpenWRT-luci branch ${OPENWRT_WORKING_BRANCH_VER}"
	cmd "git checkout ${OPENWRT_WORKING_BRANCH_VER}"
	
	cd $OPENWRT_WD/telephony
	print_log "Checkout OpenWRT-telephony branch ${OPENWRT_WORKING_BRANCH_VER}"
	cmd "git checkout ${OPENWRT_WORKING_BRANCH_VER}"
	
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
	cmd "$OPENWRT_WD/openwrt/scripts/feeds update -a"
	
	print_log "Installing local feeds"
	cmd "$OPENWRT_WD/openwrt/scripts/feeds install -a"
}

copy_x86_64_default_config () {
	cp config/${OPENWRT_DEFAULT_x86_64_CONFIG} openwrt/.config
}

build_openwrt () {
	cd ${OPENWRT_WD}/openwrt
	cmd "make defconfig"
	make -j10
}

format_block_device () {
	
	print_log "fdisk ${DEV_BLOCK}"
	printf "o\nn\n\n\n\n\n\n\nt\nc\nw\n" | cmd "sudo fdisk ${DEV_BLOCK}"
	
	print_log "Creating DOS partion on ${DEV_BLOCK}1"
	cmd "sudo mkdosfs ${DEV_BLOCK}1"
	
}

copy_image_to_media () {
		
	format_block_device
	
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
	
	print_log "Target Image:\t${img}"
	print_log "Target Device:\t${DEV_BLOCK}"
	
	cmd "gzip -fk -d $file"
	cmd "sudo dd if=$(echo "$file" | sed -e 's/\.[^.]*$//') of="${DEV_BLOCK}" bs=1M status=progress && sync "

}

prep_openwrt_branch_feeds_config () {
	change_local_openwrt_branch $OPENWRT_WORKING_BRANCH_VER
	create_local_openwrt_feeds_config
	update_local_openwrt_feeds_packages
	copy_x86_64_default_config
}

umount_device () {
	
	#Must provide a device
	[ ${1} != "" ] && {
	
		#get_lsblk_detail=`lsblk -P ${1} | tr "\n" " "`

		for blk_detail in `lsblk -P ${1} | tr "\n" " "`
		do
			
			#Match Example -> MOUNTPOINT="/media/maurice/rootfs"
			[[ $blk_detail =~ ^MOUNTPOINT=\"(.*)\"$ ]] && [ "${BASH_REMATCH[1]}" != "" ] && {	
				echo "Unmounting:  ${BASH_REMATCH[1]} on device: ${1}"
				cmd "sudo umount ${BASH_REMATCH[1]}"
			}

		done
	}
	
}

usage () {
	echo
	echo "OpenWRT x86-64 Installation"
	echo 
	echo "Version: ${VERSION}"
	echo
	echo "Usage:"
	printf "\t-b [${OPENWRT_DEFAULT_BRANCH}]\t\t\tOpenWRT install branch\n"
	printf "\t-c [LEGACY|EFI] <DEV_BLOCK>\tCreate bootable media\tExample: -c EFI /dev/sdb\n"
	printf "\t-f \t\t\t\tFresh Install, Remove previous installation\n"
	printf "\t-i\t\t\t\tIgnore Warning and Error Suppresion\n"
	printf "\t-r\t\t\t\tRemove OpenWRT directories, then exit\n"
	printf "\t-m\t\t\t\tBuild OpenWRT\n"
	printf "\t-h\t\t\t\tPrint usage and exit\n"
	printf "\t-v\t\t\t\tPrint version and exit\n"
	printf "\n\n\n"
}

							########
							#  MAIN
							########

while getopts ":b:c:firmv" OPTION; do
	case $OPTION in
	
		b) 
			OPENWRT_WORKING_BRANCH_VER="$OPTARG"
			print_log "OpenWRT branch selected:  $OPENWRT_WORKING_BRANCH_VER"
			;;

		c) 
			eval "BOOTLOADER_TYPE=\${$((OPTIND-1))}"
			eval "DEV_BLOCK=\${$((OPTIND))}"
			
			[ ${OPTARG} != "EFI" ] && [ ${OPTARG} != "LEGACY" ]  && {
				usage
				exit
			}	
			;;
			
		f) 
			FRESH_INSTALL=${TRUE}
			;;
		
		i) 
			STDOUT_REDIRECT=""
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

		?|h)
			usage
			exit
			;;
			
	esac
done
shift $((OPTIND-1))

init

[  -n "${FRESH_INSTALL}"  ] || [ ! -d "openwrt" ]  && {
	
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
	
	#Create the directory if it does not exist
	[ ! -d "${OPENWRT_WD}/openwrt/images" ] && {
		print_log "Creating image directory for x86-64 EFI and Legacy images"
		mkdir ${OPENWRT_WD}/openwrt/images 
	}
	
	#Copy images to image directory
	print_log "Copying OpenWRT images to ${OPENWRT_WD}/openwrt/images"
	cmd "cp ${OPENWRT_WD}/openwrt/bin/targets/x86/64/*.gz ${OPENWRT_WD}/openwrt/images"
 }
 
 #Make sure creating image is selected, and images directory is present
 [ "${BOOTLOADER_TYPE}" != "" ] && [ "${DEV_BLOCK}" != "" ] && [ -d "${OPENWRT_WD}/openwrt/images" ]  && {
	print_log "Creating bootable media on ${DEV_BLOCK}"
	umount_device ${DEV_BLOCK}
	copy_image_to_media	
 }
 
 
 
 
 
