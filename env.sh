#!/bin/false "This script should be sourced in a shell, not executed directly"

if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    >&2 echo "usage: source $0"
    >&2 echo "please source this shell script!"
    exit 1
fi

TASKBIN="${PWD}/bin"
GOPATH="${PWD}/cache/go"
GOBIN="${GOPATH}/bin"
TASK="${TASKBIN}/task"

# install task
[[ -x "${TASK}" ]] || scripts/install-task.sh -b "${TASKBIN}"

# export custom go environment
export GOPATH="${PWD}/cache/go"
export GO111MODULE="off"

# extend PATH
[[ $PATH != *${TASKBIN}* ]] && export PATH=${TASKBIN}:$PATH
[[ $PATH != *${GOBIN}* ]] && export PATH=${GOBIN}:$PATH
