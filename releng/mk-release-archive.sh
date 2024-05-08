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

get_collection () {
    local name
    name="$(sed -n '/^collection:/{
s,^[^:]*:[ \t]*,,
p
q
}' < "$1" | trim_space)"
    # Check that we get a single value (no spaces, no control characters, no slashes).
    [[ "${name}" ]] || die "collection missing in manifest"
    echo "${name}" | grep -vq '[/[:space:][:cntrl:]]' || die "Multiple or invalid st-version"
    echo "${name}"
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
    git -c advice.detachedHead=false clone -q --depth 1 -b "${tag}" -- "${repo}" "${dir}"

    (
	cd "${dir}"

	# Require valid signature, unless -f is in effect
	git -c "gpg.ssh.allowedSignersFile=${ALLOWED_SIGNERS}" tag --verify "${tag}" \
	    || [[ ${FORCE} = "yes" ]] || die "Component ${name} tag ${tag} is not properly signed"

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

usage () {
    echo "mk-release-archive.sh [OPTIONS] MANIFEST-FILE [FILE ... ]"
    echo "Create a .tar.gz archive based on the components listed in the manifest file."
    echo "Any additional files are copied into the top-level of the archived directory."
    echo
    echo "Options:"
    echo "  -o DIR  Use directory DIR and create archive 'DIR.tar.gz'"
    echo "            Only the last directory component is included in the archive."
    echo "            (default: name from collection-line in the manifest)."
    echo "  -a FILE OpenSSH allowed signers file (default: 'allowed_signers')."
    echo "  -f      Force-create archive even if tags are not properly signed."
    echo "  -h      Display this help."
}

FORCE=no

while getopts "hfa:o:" option ; do
    case "${option}" in
	h)
	    usage
	    exit 0
	    ;;
	o)
	    DIST_DIR="${OPTARG}"
	    ;;
	a)
	    ALLOWED_SIGNERS="${OPTARG}"
	    ;;
	f)
	    FORCE=yes
	    ;;
	*)
	    usage >&2
	    exit 1
    esac
done

shift $(( OPTIND - 1 ))

[[ $# -ge 1 ]] || die "Missing argument, see mk-release-archive.sh -h for help"

MANIFEST="$1"
shift

COLLECTION="$(get_collection "${MANIFEST}")"
: "${DIST_DIR:="${COLLECTION}"}"

if [[ ${FORCE} = "yes" ]] ; then
    : "${ALLOWED_SIGNERS:=/dev/null}"
else
    : "${ALLOWED_SIGNERS:=allowed_signers}"
fi

# Needs an absolute filename
ALLOWED_SIGNERS="$(realpath "${ALLOWED_SIGNERS}")"

# Consider just rm -rf ${DIST_DIR}.
[[ ! -a ${DIST_DIR} ]] || die "Directory ${DIST_DIR} already exists."

msg "Creating ${DIST_DIR}"
mkdir "${DIST_DIR}"

get_component_list "${MANIFEST}" | while read -r git_repo tag hash ; do
    download_component "${git_repo}" "${tag}" "${hash}"
done

LATEST_COMPONENT="$(ls --zero -At "${DIST_DIR}" | head -z -n1 | tr -d "\0")"

[[ ! -e  "${DIST_DIR}/manifest" ]] || die "'manifest' file already exists in target dir!"
cp "${MANIFEST}" "${DIST_DIR}/manifest"

for f in "$@" ; do
    [[ ! -e "${DIST_DIR}/$(basename "$f")" ]] || die "file '$(basename "$f")' already exists in target dir!"
    cp "$f" "${DIST_DIR}"
done

(
    echo tar: "$(tar --version | head -1)"
    echo gzip: "$(gzip --version | head -1)"
) > "${DIST_DIR}/archiving-tools.txt"

( cd "$(dirname "${DIST_DIR}")" &&
  tar --exclude .git --sort=name --format=posix \
  --pax-option=exthdr.name=%d/PaxHeaders/%f \
  --pax-option=delete=atime,delete=ctime \
  --clamp-mtime --mtime="./$(basename "${DIST_DIR}")/${LATEST_COMPONENT}" \
  --numeric-owner --owner=0 --group=0 \
  --mode=go+u,go-w \
  -cf - "$(basename "${DIST_DIR}")" ) | gzip --no-name --best > "${DIST_DIR}.tar.gz"
