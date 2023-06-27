#!/usr/bin/env bash

set -Eeuo pipefail

TIMEOUT=300
LOG=
LOG=/tmp/qemu.log
TARGET=$1

declare -a MATCH
#Ubuntu Focal
MATCH+=("Ubuntu 20.04 LTS ubuntu ttyS0")
#Ubuntu Bionic
MATCH+=("Ubuntu 18.04 LTS ubuntu ttyS0")
#Debian Buster
MATCH+=("Debian GNU/Linux 10 debian ttyS0")

# run qemu
task qemu:"$TARGET" </dev/null | tee /dev/stderr > "$LOG" &

i=0
while [ "$i" -lt "$TIMEOUT" ]
do
	for m in "${MATCH[@]}"
	do
		if grep -q "$m" "$LOG" >/dev/null 2>&1
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
