#! /bin/bash

# Script to unpack a tarball and attempt to build it. Intended to work
# for all st 1.* collection releases.


set -eu

die() {
    echo "$@"
    exit 1
}

[[ $# -eq 1 ]] || die "Requires a single argument, the .tar.gz file to test"

# Need absolute file name, to make it work after changing directory.
TARFILE="$(realpath "$1")"

# Change directory to where script is located.
cd "$(dirname "$0")"

# To ignore the irrelevant git state in the parent directory.
export GOFLAGS='-buildvcs=false'

rm -rf test-tmp
mkdir test-tmp
cd test-tmp

GOBIN="$(pwd)/bin"
export GOBIN

tar xzf "${TARFILE}"

DIR="$(basename "${TARFILE}" .tar.gz)"

[[ -d "${DIR}" ]] || die "Unexpected unpacked directory name"

echo "RUNNING stboot tests"

# Use go work to make stboot integration tests use stmgr from the
# collection.
(cd "${DIR}"/stboot/integration && go work init && go work use . ../../stmgr)

(cd "${DIR}"/stboot && go test ./...)
./"${DIR}"/stboot/integration/qemu-boot-from-net.sh
./"${DIR}"/stboot/integration/supermicro-x11scl-bond-iso.sh
cp "${DIR}"/stboot/integration/out/stboot.iso stboot.iso

# Test that if there is a --version option, we can configure it at build time
(cd "${DIR}"/stboot
     if go run . --version >/dev/null 2>&1 ; then
	 echo "TESTING compile time stboot version"
	 go build -ldflags="-X main.ConfiguredVersion=collection-test"
	 STBOOT_VERSION="$(./stboot --version)"
	 [[ "${STBOOT_VERSION}" = "stboot version: collection-test" ]] \
	     || die "Failed to set stboot version, got: ${STBOOT_VERSION}"
     fi
)

echo "RUNNING stmgr tests"

(cd "${DIR}"/stmgr && go work init && go work use . ../stboot && go test ./... && make check)

# Make stprov supermicro-x11scl.sh test use stmgr from the collection.
# For stprov up to v0.3.x, we need to install it in PATH. From v0.4.1,
# it is configured using go.mod. Unfortunately, using go.work or
# GOWORK doesn't quite work, at least not with stprov@v0.4.2 (using
# go.work fails, because it interacts badly with u-root, and using
# GOWORK fails because both scripts also build the stprov executable,
# and then GOWORK is applied also to the top-level module rather than
# to the testonly module it was intended for). Instead add a replace
# directive to the go.mod file.
if [[ -f "${DIR}"/stprov/integration/go.mod ]] ; then
    echo 'replace system-transparency.org/stmgr => ../../stmgr' >> "${DIR}"/stprov/integration/go.mod
    (cd "${DIR}"/stprov/integration/ && go mod tidy)
    ENV=()
else
    (cd "${DIR}"/stmgr && go install .)
    ENV=("PATH=${GOBIN}:${PATH}")
fi

echo "RUNNING stprov tests"

(cd "${DIR}"/stprov && go test ./...)

# Workaround for unexpected stprov version
if grep >/dev/null '^component: https://git.glasklar.is/system-transparency/core/stprov.git v0.4.2 831035a66841c1968787ab51c2c2d76b975f1397$' "${DIR}"/manifest ; then
    echo "Applying workaround for issue https://git.glasklar.is/system-transparency/core/stprov/-/issues/96"
    sed -i 's/stprov version v\[^ \]\*; timestamp/stprov version [^ ]*; timestamp/' "${DIR}"/stprov/integration/qemu.sh
fi
if grep >/dev/null '^component: https://git.glasklar.is/system-transparency/core/stprov.git v0.5.4 d0acca1fea8138cb7e23ec02e61c0fa026730b7a$' "${DIR}"/manifest ; then
    echo "Applying workaround for issue https://git.glasklar.is/system-transparency/core/stprov/-/issues/96"
    sed -i 's/stprov version v\[^ \]\*; timestamp/stprov version [^ ]*; timestamp/' "${DIR}"/stprov/integration/qemu.sh
fi

env "${ENV[@]}" ./"${DIR}"/stprov/integration/qemu.sh
env "${ENV[@]}" ./"${DIR}"/stprov/integration/supermicro-x11scl.sh
cp "${DIR}"/stprov/integration/build/stprov.iso stprov.iso

echo "All tests pass. To test on hardware, boot test-tmp/{stboot,stprov}.iso."
