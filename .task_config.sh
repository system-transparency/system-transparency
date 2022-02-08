#!/usr/bin/env bash

set -euo pipefail

# config file location
CONFIG_FILE="${CONFIG}"
# location to save target subconfigs
CONFIG_DATA='.task/config'

if [[ "$#" -lt 2 ]]; then
	echo "Usage ${0##*/} <name> [config_name list]"
	exit 1
fi

# parse args
NAME="${1}"
shift 1
CONFIG_LIST=( "$@" )

# target subconfig file location
SUBCONFIG="${CONFIG_DATA}/${NAME}"

# check if config file exist
if [[ ! -f "${CONFIG_FILE}" ]]; then
	>&2 echo "Config file \"${CONFIG_FILE}\" missing"
	exit 1
fi

source "${CONFIG_FILE}"

create_subconfig() {
	CONFIG="$1"
	touch "${CONFIG}"
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
