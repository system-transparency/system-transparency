TASKBIN="${PWD}/task"

[[ -x "${TASKBIN}" ]] || ./install-task.sh

alias task="${TASKBIN}"
