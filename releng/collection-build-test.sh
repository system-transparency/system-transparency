#! /bin/bash

# Script to unpack a tarball and attempt to build it. Currently very
# tailored to the contents of the st 1.0.0 collection release.


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

rm -rf test-tmp
mkdir test-tmp
cd test-tmp

tar xzf "${TARFILE}"

DIR="$(basename "${TARFILE}" .tar.gz)"

[[ -d "${DIR}" ]] || die "Unexpected unpacked directory name"

echo RUNNING stboot tests

# Use go work to make stboot integration tests use stmgr from the
# collection.
(cd "${DIR}"/stboot/integration && go work init && go work use . ../../stmgr)

(cd "${DIR}"/stboot && go test ./...)
./"${DIR}"/stboot/integration/qemu-boot-from-net.sh
./"${DIR}"/stboot/integration/supermicro-x11scl-bond-iso.sh
cp "${DIR}"/stboot/integration/out/stboot.iso stboot.iso

echo RUNNING stmgr tests

(cd "${DIR}"/stmgr && go work init && go work use . ../stboot && go test ./... && make check)

# To get stprov integration to use stmgr from the collection, install it in PATH.
GOBIN="$(pwd)/bin"
export GOBIN
(cd "${DIR}"/stmgr && go install .)

PATH="${GOBIN}:${PATH}"

echo RUNNING stprov tests

(cd "${DIR}"/stprov && go test ./...)

PATH="${GOBIN}:${PATH}" ./"${DIR}"/stprov/integration/qemu.sh
PATH="${GOBIN}:${PATH}" ./"${DIR}"/stprov/integration/supermicro-x11scl.sh
cp "${DIR}"/stprov/integration/build/stprov.iso stprov.iso

echo "All tests pass. To test on hardware, boot test-tmp/{stboot,stprov}.iso."
