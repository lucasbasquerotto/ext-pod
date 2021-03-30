#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

pod_script_env_file="$var_pod_script"

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
	"test")
		>&2 "$pod_script_env_file" "s3:subtask:s3_backup" \
			--s3_cmd=delete_old \
			--s3_path="db" \
			--s3_older_than_days="5" \
			--s3_test='false'
		;;
	"clear")
		"$pod_script_env_file" "local:clear"
		sudo docker volume rm -f "${var_run__general__ctx_full_name}_mongo_db"
		sudo docker volume rm -f "${var_run__general__ctx_full_name}_uploads"
		;;
	"clear-all")
		"$pod_script_env_file" "local:clear-all"
		;;
	"clear-remote")
		if [ "${var_custom__use_s3:-}" = 'true' ]; then
			"$pod_script_env_file" "s3:subtask:s3_uploads" --s3_cmd=rb
			"$pod_script_env_file" "s3:subtask:s3_backup" --s3_cmd=rb

			if [ "${var_run__enable__uploads_replica:-}" = 'true' ]; then
				"$pod_script_env_file" "s3:subtask:s3_uploads_replica" --s3_cmd=rb
			fi

			if [ "${var_run__enable__backup_replica:-}" = 'true' ]; then
				"$pod_script_env_file" "s3:subtask:s3_backup_replica" --s3_cmd=rb
			fi
		fi
		;;
	*)
		"$pod_env_shared_file" "$command" "$@"
		;;
esac