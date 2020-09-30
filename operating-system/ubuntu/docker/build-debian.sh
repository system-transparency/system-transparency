#!/bin/bash
#
# build a debian reproducible with debos
# MIT
# 2019 Alexander Couzens <lynxis@fe80.eu>

export LC_ALL=C
export LANG=C
export TZ=UTC

set -e

cd "$(dirname "$0")"
TOP=$(pwd)
export TOP

source_date_version() {
	[ -f version.date ] || return 1
	SOURCE_DATE_EPOCH="$(cat version.date)"
	[ -n "$SOURCE_DATE_EPOCH" ]
}

source_date_git() {
	SOURCE_DATE_EPOCH="$(git log -1 --format=format:%ct)"
	[ -n "$SOURCE_DATE_EPOCH" ]
}

document_debpkg() {
	pkg=$1
	version=$(dpkg -s "$pkg" | grep '^Version' | cut -d " " -f2)
	echo "DEB_PKG_${pkg}: ${version}"
}

document_build_info() {
	{
		document_debpkg debos
	} > ./document_build.info
}

build_debian_image() {
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
		--artifactdir="$TOP/out/" \
		"${dargs[@]}" \
		./debos.yaml

	if [ ! -z "$DEBOS_USER_ID" ]; then
		chown -R $DEBOS_USER_ID:$DEBOS_GROUP_ID "$TOP/out"
	fi
}

# set source date epoch
source_date_version || source_date_git || SOURCE_DATE_EPOCH=""
if [ -z "$SOURCE_DATE_EPOCH" ] ; then
	echo "Can not find SOURCE_DATE_EPOCH!" >&2
	exit 1
fi
export SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
mkdir -p "$TOP/out"

document_build_info
build_debian_image
