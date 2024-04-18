#! /bin/bash

# We consistently use GNU ls with --zero, which should be ok.
# shellcheck disable=SC2012

# See
# https://www.gnu.org/software/tar/manual/html_node/Reproducibility.html
# for suitable tar flags, and advice on timestamps.

set -eu

export TZ=UTC0
export LC_ALL=C

die() {
    echo "$@"
    exit 1
}

msg() {
    echo "$@" >&2
}

trim_space () {
    sed 's,^[ \t]*,,
s,[ \t]*$,,'
}

get_version () {
    local version
    version="$(sed -n '/^st-version:/{
s,^[^:]*:[ \t]*,,
p
q
}' < "$1" | trim_space)"
    # Check that we get a single value (no spaces, no control characters, no slashes).
    [[ "${version}" ]] || die "st-version missing in manifest"
    echo "${version}" | grep -vq '[/[:space:][:cntrl:]]' || die "Multiple or invalid st-version"
    echo "${version}"
}

get_component_list () {
    sed -n '/^component:/{
s,^[^:]*:,,
p
}' < "$1" | trim_space
}

commit_hash() {
    git show -s --format='tformat:%H' "$@"
}

# Commit time in seconds since unix epoch.
commit_seconds() {
    git show -s --format=tformat:%cd \
    --date=unix \
    "$@"
}
download_component () {
    local repo="$1"
    local tag="$2"
    local hash="$3"
    local name
    name="$(basename "${repo}" .git)"
    local dir="${DIST_DIR}/${name}"

    # Make a detached checkout at HEAD.
    msg "Checking out ${name}"

    # TODO: Unnecessarily verbose, even with -q.
    git clone -q --depth 1 -b "${tag}" -- "${repo}" "${dir}"

    (
	cd "${dir}"

	# TODO: Should require valid signatures by default, with
	# option to allow unsigned tags.
	git tag --verify "${tag}" \
	    || msg "Component ${name} tag ${tag} not properly signed"

	[[ "${hash}" = "$(commit_hash HEAD)" ]] \
	    || die "Unexpected hash for component ${name} tag ${tag}"

	# Set modification time according to commit time, similar to
	# example in tar manual.
	git ls-files -z | while read -r -d '' file; do
	    touch -md @"$(commit_seconds "${file}")" "${file}"
	done
	# All checked out directories are non-empty. Set mtime of each
	# directory to that of its newest entry, depth first.
	# Unfortunately, -prune is not effective in combination with
	# -depth, so we need to match and exclude all subdirectories
	# under .git/.
	find . -depth -type d '(' -name .git -o -path '*/.git/*' -o -exec bash -c '
	  touch -mr "$1/$(ls --zero -At "$1" | grep -z -v "^.git\$" | head -z -n1 | tr -d "\0")" "$1"' bash '{}' ';' ')'
    )
}
[[ $# = 1 ]] || die "Wants exactly one argument, the manifest file."

MANIFEST="$1"

VERSION="$(get_version "${MANIFEST}")"
DIST_DIR="st-${VERSION}"

# Consider just rm -rf ${DIST_DIR}.
[[ ! -a ${DIST_DIR} ]] || die "Directory ${DIST_DIR} already exists."

msg "Creating ${DIST_DIR}"
mkdir "${DIST_DIR}"

get_component_list "${MANIFEST}" | while read -r git_repo tag hash ; do
    download_component "${git_repo}" "${tag}" "${hash}"
done

LATEST_COMPONENT="$(ls --zero -At "${DIST_DIR}" | head -z -n1 | tr -d "\0")"

cp "${MANIFEST}" "${DIST_DIR}/"

(
    echo tar: "$(tar --version | head -1)"
    echo gzip: "$(gzip --version | head -1)"
) > "${DIST_DIR}/archiving-tools.txt"


tar --exclude .git --sort=name --format=posix \
  --pax-option=exthdr.name=%d/PaxHeaders/%f \
  --pax-option=delete=atime,delete=ctime \
  --clamp-mtime --mtime="./${DIST_DIR}/${LATEST_COMPONENT}" \
  --numeric-owner --owner=0 --group=0 \
  --mode=go+u,go-w \
  -cf - "${DIST_DIR}" | gzip --no-name --best > "${DIST_DIR}.tar.gz"
