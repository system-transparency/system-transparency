TASKBIN="${PWD}/bin/task"

[[ -x "${TASKBIN}" ]] || scripts/install-task.sh

alias task="${TASKBIN}"
