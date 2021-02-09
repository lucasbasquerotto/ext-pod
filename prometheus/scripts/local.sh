#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

# shellcheck disable=SC2153
pod_script_env_file="$POD_SCRIPT_ENV_FILE"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
}

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env)."
fi

shift;

pod_env_shared_file="$var_run__general__script_dir/shared.sh"

case "$command" in
	"clear")
		"$pod_script_env_file" "local:clear"
		sudo docker volume rm -f "${var_run__general__ctx_full_name}_grafana"
		sudo docker volume rm -f "${var_run__general__ctx_full_name}_prometheus"
		;;
	"clear-all")
		"$pod_script_env_file" "local:clear-all"
		;;
	"clear-remote")
		"$pod_script_env_file" "s3:subtask:s3_backup" --s3_cmd=rb
		;;
	*)
		"$pod_env_shared_file" "$command" "$@"
		;;
esac