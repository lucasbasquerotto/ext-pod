#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

pod_script_env_file="$var_pod_script"
pod_env_shared_file="$var_run__general__script_dir/shared.sh"

function info {
	"$pod_env_shared_file" "util:info" --info="${*}"
}

function error {
	"$pod_env_shared_file" "util:error" --error="${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
}

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env)."
fi

shift;

case "$command" in
	"clear")
		"$pod_script_env_file" "local:clear"
		sudo docker volume rm -f "${var_run__general__ctx_full_name}_mysql"
		sudo docker volume rm -f "${var_run__general__ctx_full_name}_uploads"
		;;
	"clear-all")
		"$pod_script_env_file" "local:clear-all"
		;;
	"clear-remote")
		"$pod_script_env_file" "s3:subtask:s3_uploads" --s3_cmd=rb
		"$pod_script_env_file" "s3:subtask:s3_backup" --s3_cmd=rb
		"$pod_script_env_file" "s3:subtask:s3_uploads_replica" --s3_cmd=rb
		"$pod_script_env_file" "s3:subtask:s3_backup_replica" --s3_cmd=rb
		;;
	*)
		"$pod_env_shared_file" "$command" "$@"
		;;
esac