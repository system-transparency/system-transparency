#! /usr/bin/bash

set -eu
signing_key="$1"; shift

dir=$(dirname "$0")
source "${dir}"/reldef.sh

function dlfun {
    local arts="$1"; shift
    for a in $arts; do
	local method="${artmap[$a:method]}"
	if [[ "$method" != "git" ]]; then
	    printf "%s: method \"%s\" != \"git\", ignored\n" "$a" "$method"
	    continue
	fi

	local url="${artmap[$a:url]}"
	local ver="${artmap[$a:version]}"
	printf "%s: cloning %s@%s ..." "$a" "$url" "$ver"
	git clone --quiet --single-branch --depth 1 --branch "$ver" "$url" "${a}-${ver}" 2>/dev/null
	printf "\n"
    done
}

function tarfun {
    local -r tarfile="$1"; shift
    local -r arts="$1"; shift
    local dirnames=
    for a in $arts; do
	local ver="${artmap[$a:version]}"
	dirnames+="${a}-${ver} "
    done
    printf "taring into %s\n" "${tarfile}"
    tar cJf "${tarfile}" --exclude .git --exclude .gitignore --exclude .gitlab-ci.yml --exclude .golangci.yml $dirnames
}

function signfun {
    local -r tarfile="$1"; shift
    local -r keyfile="$1"; shift

    ssh-keygen -Y sign -O hashalg=sha256 -f "$keyfile" -n "$ST_SSHSIG_NAMESPACE" "$tarfile"
}

function verifyfun {
    local -r tarfile="$1"; shift
    local -r allowed_signers="${dir}/${ST_SSHSIG_ALLOWED_SIGNERS_FILE}"

    ssh-keygen -Y verify -f "$allowed_signers" -n "$ST_SSHSIG_NAMESPACE" -I "$ST_SSHSIG_SIGNER_NAME" -s "${tarfile}.sig" < "$tarfile"
}

tarfile="st-${ST_VERSION}.tar.xz"
dlfun "$artefacts"
tarfun "$tarfile" "$artefacts"
signfun "$tarfile" "$signing_key"
verifyfun "$tarfile"
