#!/bin/bash
set -eou pipefail

tmp_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2154
tmp_pod_layer_dir="$var_pod_layer_dir"

export var_load_name='mattermost'
export var_load_main__db_service='postgres'
export var_load_main__db_backup_task="db:main:${var_load_main__db_service:-}:backup:file"
export var_load_main__db_restore_task="db:main:${var_load_main__db_service:-}:restore:file"
export var_load_main__db_backup_is_file='true'
export var_load_main__db_backup_extension='dump'

export var_load_general__orchestration='compose'
export var_load_general__toolbox_service='toolbox'
export var_load_general__script_dir="$tmp_dir"
export var_load_general__script_env_file='remote.sh'

if [ "${var_load_main__local:-}" = 'true' ]; then
	export var_load_general__script_env_file='local.sh'
fi

if [ "${var_load_enable__db_backup:-}" = 'true' ] && [ "${var_load_use__wale:-}" = 'true' ]; then
	export var_load_enable__db_backup='false'
	export var_load_enable__custom_db_backup='true'
fi

if [ "${var_load_enable__db_setup:-}" = 'true' ] && [ "${var_load_use__wale_restore:-}" = 'true' ]; then
	export var_load_enable__db_setup='false'
	export var_load_enable__custom_db_setup='true'
fi

function tmp_error {
	echo "${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}" >&2
	exit 2
}

tmp_errors=()

# specific vars...

tmp_is_db=''

if [ "${var_load_main__pod_type:-}" = 'app' ] || [ "${var_load_main__pod_type:-}" = 'db' ]; then
	tmp_is_db='true'
fi

if [ "$tmp_is_db" = 'true' ]; then
	if [ "${var_load_enable__custom_db_backup:-}" = 'true' ] && [ "${var_load_use__wale:-}" = 'true' ]; then
		export var_task__db_backup__task__type='backup'
		export var_task__db_backup__backup_task__subtask_cmd_local=''
		export var_task__db_backup__backup_task__subtask_cmd_remote='shared:db:task:backup_db'
		export var_task__db_backup__backup_task__no_src_needed='true'

		export var_task__db_backup__backup_db__task_name='db_main'
		export var_task__db_backup__backup_db__db_subtask_cmd='db:main:postgres:backup:wale'
	fi

	if [ "${var_load_enable__custom_db_setup:-}" = 'true' ] && [ "${var_load_use__wale_restore:-}" = 'true' ]; then
		if [ -z "${var_load__db_setup__pitr:-}" ]; then
			tmp_errors+=("wale: var_load__db_setup__pitr (point in time recovery of the backup) is not defined")
		fi

		tmp_default_file_to_skip='/tmp/main/setup/db.skip'
		tmp_file_to_skip="${var_load__db_setup__verify_file_to_skip:-$tmp_default_file_to_skip}"

		export var_task__db_setup__task__type="setup"
		export var_task__db_setup__setup_task__verify_file_to_skip="$tmp_file_to_skip"
		export var_task__db_setup__setup_task__subtask_cmd_verify='shared:db:task:setup_verify'
		export var_task__db_setup__setup_task__subtask_cmd_remote='shared:db:task:setup_db'
		export var_task__db_setup__setup_task__subtask_cmd_local=''

		export var_task__db_setup__setup_verify__db_subtask_cmd='db:main:postgres:restore:verify'
		export var_task__db_setup__setup_verify__task_name="db_main"

		export var_task__db_setup__setup_db__task_name='db_main'
		export var_task__db_setup__setup_db__db_subtask_cmd='db:main:postgres:restore:wale'
		export var_task__db_setup__setup_db__pit="${var_load__db_setup__pitr:-}"
		export var_task__db_setup__setup_db__db_args="${var_load__db_setup__db_args:-}"
	fi
fi

# final section

tmp_error_count=${#tmp_errors[@]}

if [[ $tmp_error_count -gt 0 ]]; then
	echo "[specific errors]" >&2

	for (( i=1; i<tmp_error_count+1; i++ )); do
		echo "$i/${tmp_error_count}: ${tmp_errors[$i-1]}" >&2
	done
fi

tmp_error_count_aux="$tmp_error_count"
tmp_error_count=0

# shellcheck disable=SC1090,SC1091
. "$tmp_pod_layer_dir/shared/scripts/shared.vars.sh"

tmp_shared_error_count="${tmp_error_count:-0}"

tmp_final_error_count=$((tmp_error_count_aux + tmp_shared_error_count))

if [[ $tmp_final_error_count -gt 0 ]]; then
	tmp_error "$tmp_final_error_count error(s) when loading the variables"
fi