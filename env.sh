#!/bin/false "This script should be sourced in a shell, not executed directly"

if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    >&2 echo "usage: source $0"
    >&2 echo "please source this shell script!"
    exit 1
fi

TASKBIN="${PWD}/bin"
GOBIN="${PWD}/cache/go/bin"
TASK="${TASKBIN}/task"

[[ -x "${TASK}" ]] || scripts/install-task.sh -b "${TASKBIN}"
[[ $PATH != *${TASKBIN}* ]] && export PATH=${TASKBIN}:$PATH
[[ $PATH != *${GOBIN}* ]] && export PATH=${GOBIN}:$PATH
