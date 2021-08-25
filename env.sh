TASKBIN="${PWD}/bin"
GOBIN="${PWD}/cache/go/bin"
TASK="${TASKBIN}/task"

[[ -x "${TASK}" ]] || scripts/install-task.sh -b "${TASKBIN}"

if [[ $PATH != *${TASKBIN}* ]];
then
  export PATH=${LOCALBIN}:$PATH
fi

if [[ $PATH != *${GOBIN}* ]];
then
  export PATH=${GOBIN}:$PATH
fi
