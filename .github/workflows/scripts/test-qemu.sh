#!/bin/bash

[ "$#" -ne 1 ] && echo "run: ${0} <mbr/efi>" && exit 1

TIMEOUT=300
LOG=
TARGET=
IMAGE=
case $1 in
	"mbr")
		LOG=/tmp/mbr-qemu.log
		TARGET=run-mbr-bootloader
		IMAGE=stboot_mbr_installation.img
		;;
	"efi")
		LOG=/tmp/efi-qemu.log
		TARGET=run-efi-application
		IMAGE=stboot_efi_installation.img
		;;
	*)
		echo "unknown installation: $1."
		exit 1
		;;
esac

declare -a MATCH
#Ubuntu Focal
MATCH+=("Ubuntu 20.04 LTS ubuntu ttyS0")
#Ubuntu Bionic
MATCH+=("Ubuntu 18.04 LTS ubuntu ttyS0")
#Debian Buster
MATCH+=("Debian GNU/Linux 10 debian ttyS0")

cleanup () {
	make_pid=$(pgrep -f ${TARGET})
	qemu_pid=$(pgrep -f ${IMAGE})
	for pid in "${make_pid} ${qemu_pid}"
	do
		if [ ! -z "${qemu_pid}" ];
		then
			kill -TERM "${qemu_pid}"
		fi
	done
}

trap cleanup EXIT

# run qemu
make ${TARGET} </dev/null | tee /dev/stderr > "$LOG" &

i=0
while [ "$i" -lt "$TIMEOUT" ]
do
	for m in "${MATCH[@]}"
	do
		if grep -q "$m" "$LOG"
		then
			echo "loginshell reached. Boot successful"
			exit 0
		fi
	done
	sleep 1
	i=$((i+1))
done

echo "TIMEOUT"
exit 1
