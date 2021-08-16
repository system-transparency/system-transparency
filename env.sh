LOCALBIN="${PWD}/bin"
TASKBIN="${LOCALBIN}/task"

[[ -x "${TASKBIN}" ]] || scripts/install-task.sh

if [[ $PATH != *${LOCALBIN}* ]];
then
  export PATH=${LOCALBIN}:$PATH
fi
