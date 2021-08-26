#!/usr/bin/env bash

set -euo pipefail

# config file location
CONFIG_FILE='.config'
# location to save target subconfigs
CONFIG_DATA='.task/config'
# config name pattern
# XXX: define a naming convention
CONFIG_PAT='ST_[A-Z_]*'

if [[ "$#" -ne 2 ]]; then
	echo "Usage ${0##*/} <name> <script>"
	exit 1
fi

NAME="${1}"
SCRIPT="${2}"

# target subconfig file location
SUBCONFIG="${CONFIG_DATA}/${NAME}"

# check if script exist
if [[ ! -f "${SCRIPT}" ]]; then
	>&2 echo "Script \"${SCRIPT}\" not found"
	exit 1
fi

# check if config file exist
if [[ ! -f "${CONFIG_FILE}" ]]; then
	>&2 echo "Config file \"${CONFIG_FILE}\" missing"
	exit 1
fi

source "${CONFIG_FILE}"

create_subconfig() {
	CONFIG="$1"
	touch "${CONFIG}"
	# read all accuring configs into a sorted array
	read -a CONFIG_LIST <<< "$(grep -o "${CONFIG_PAT}" "${SCRIPT}" | sort | uniq | tr '\n' ' ')"
	# parse relevant configs to subconfig
	for config in "${CONFIG_LIST[@]}"; do
		echo "${config}=\"${!config:-}\"" >> "$CONFIG"
	done
}

if [[ ! -f "${SUBCONFIG}" ]]; then
	# create subconfig
	mkdir -p "${CONFIG_DATA}"
	create_subconfig "${SUBCONFIG}"
	echo "subconfig created"
	exit 1
fi

# create temporary subconfig
tmp_subconfig="$(mktemp)"
trap "rm -f ${tmp_subconfig}" EXIT

create_subconfig "${tmp_subconfig}"

# check if subconfig changed
if diff "${tmp_subconfig}" "${SUBCONFIG}"; then
	echo "no change in subconfig"
else
	echo "subconfig changed"
	cp "${tmp_subconfig}" "${SUBCONFIG}"
	exit 1
fi
