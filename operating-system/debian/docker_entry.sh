#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../../" && pwd)"

export LC_ALL=C
export LANG=C
export TZ=UTC

out="${root}/out/operating-system"

source_date_version() {
	[ -f version.date ] || return 1
	SOURCE_DATE_EPOCH="$(cat version.date)"
	[ -n "$SOURCE_DATE_EPOCH" ]
}

source_date_git() {
	SOURCE_DATE_EPOCH="$(git log -1 --format=format:%ct)"
	[ -n "$SOURCE_DATE_EPOCH" ]
}


cd "${dir}"

# set source date epoch
source_date_version || source_date_git || SOURCE_DATE_EPOCH=""
if [ -z "$SOURCE_DATE_EPOCH" ] ; then
	echo "Can not find SOURCE_DATE_EPOCH!" >&2
	exit 1
fi

export SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
mkdir -p "${out}"

dargs=()
if [ -e /.dockerenv ] ; then
	if ! debos --help 2>&1 | grep -q -- --chroot ; then
		echo "Your debos does not support --chroot !"
		echo "Please use a newer debos version or the debos from https://github.com/system-transparency/debos"
		exit 1
	fi

	dargs+=("--chroot")
fi

if debos --help 2>&1 |grep -q -- --disable-fakemachine ; then
	dargs+=("--disable-fakemachine")
fi

debos \
	"--environ-var=SOURCE_DATE_EPOCH:$SOURCE_DATE_EPOCH" \
	"--environ-var=LC_ALL:$LC_ALL" \
	"--environ-var=LANG:$LANG" \
	"--environ-var=TZ:$TZ" \
	--artifactdir="${out}" \
	"${dargs[@]}" \
	./debos.yaml

if [ ! -z "$DEBOS_USER_ID" ]; then
	chown -R "$DEBOS_USER_ID":"$DEBOS_GROUP_ID" "${out}"
fi

trap - EXIT
