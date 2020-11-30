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
OPENWRT_WD=$PWD

EPOCH=`date +%s`

LOG_FILE_PATH="${OPENWRT_WD}/log"
LOG_FILE="${LOG_FILE_PATH}/build_log-${EPOCH}.log"

DEV_BLOCK="/dev/sdb"
BOOTLOADER_TYPE="LEGACY"
STDOUT_REDIRECT=" &> /dev/null"

cmd () {	
	_cmd="$1 ${STDOUT_REDIRECT}"
	eval ${_cmd}
}

print_log () {
	
	string=$1
	
	time_stamp="[`date +%m-%d-%Y-%T`]"
	
	echo "${time_stamp} $string" >> ${LOG_FILE}
	
	printf "${time_stamp} ${string}\n"
	
}

unmount () {
	DEV_BLOCK=$1
	
	partionList=`lsblk -l ${DEV_BLOCK} -o NAME,TYPE -n | grep part | awk '{print $1}'`
	
	for part in $partionList; do
		print_log "Unmounting /dev/${part}"
    		cmd "sudo umount /dev/${part}"
	done

}

format_device () {
	
	# Example /dev/sdX
	blockDev=${1}	
		
	print_log "fdisk ${blockDev}"
	printf "o\nn\n\n\n\n\n\n\nt\nc\nw\n" | cmd "sudo fdisk ${blockDev}"
	
	print_log "Creating DOS partion on ${blockDev}1"
	cmd "sudo mkdosfs ${blockDev}1"
	
}

copy_image_to_disk () {
	
	# /dev/sdb
	blockDev=$1
	
	# EFI or LEGACY
	bootloaderType=$2
	
	unmount ${blockDev}
	
	format_device ${blockDev}
	
	bt=""
	
	[ ${bootloaderType} == "EFI" ] && { 
		print_log "EFI image selected"
		bt="-efi"		
	}
	
	###################################################
	# EFI -> openwrt-x86-64-generic-ext4-combined-efi.img.gz
	# LEG -> openwrt-x86-64-generic-ext4-combined.img.gz
	###################################################
	
	img="openwrt-x86-64-combined-ext4${bt}.img.gz"
	file="${OPENWRT_WD}/openwrt/images/${img}"
	
	print_log "Target Image:\t${img}"
	print_log "Target Device:\t${blockDev}"
	
	cmd "gzip -fk -d $file"
	cmd "sudo dd if=$(echo "$file" | sed -e 's/\.[^.]*$//') of="${blockDev}" bs=1M status=progress && sync"
		
	resize_partion $blockDev $bt

}

resize_partion () {

	# /dev/sdb
	blockDev=$1
	
	# EFI or LEGACY
	bt=$2

	# Non-UEFI Installation
	[[ ${bt} == "" ]] && {
		
		#PATH       TYPE   SIZE
		#/dev/sdb   disk    28G
		#/dev/sdb1  part    16M
		#/dev/sdb2  part  26.1G
		disk_size=`lsblk -io PATH,TYPE,SIZE | grep ${blockDev} | grep disk | awk '{print $3}'`
		
		#Resize the second partion
		print_log "Resizing second partion: ${blockDev} -> ${disk_size}"
		cmd "sudo parted ${blockDev} resizepart 2 ${disk_size}"
		
		#Impliment the resized partion
		print_log "Final resizing second partion: ${blockDev} -> ${disk_size}"
		cmd "sudo resize2fs ${blockDev}"
	}

}

usage () {
	echo
	echo "OpenWRT - Copy x86_64 image to media"
	echo 
	echo "Version: ${VERSION}"
	echo
	echo "Usage:"
	printf "\t-m <Device Block>\t\tMedia or Device Block\tExample: -m /dev/sdb\n"
	printf "\t-b [LEGACY]|EFI\t\t\tCreate bootable media\tExample: -b EFI\n"
	printf "\t-h\t\t\t\tPrint usage and exit\n"
	printf "\t-v\t\t\t\tPrint version and exit\n"
	printf "\n\n\n"
}

							########
							#  MAIN
							########
if [[ $1 == "" ]]; then
	usage;
	exit;
fi

while getopts ":m:b:c:hv" OPTION; do
	case $OPTION in
	
		m) 
			DEV_BLOCK="$OPTARG"
			print_log "Media Location:  $DEV_BLOCK"
			;;

		b) 
			eval "BOOTLOADER_TYPE=\${$((OPTIND-1))}"
			
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

copy_image_to_disk $DEV_BLOCK $BOOTLOADER_TYPE


