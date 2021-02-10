#!/bin/bash
set -eou pipefail

tmp_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2154
tmp_pod_layer_dir="$var_pod_layer_dir"

export var_load_name='efk'
export var_load_main__db_service='elasticsearch'
export var_load_main__db_backup_include_src='true'

export var_load_general__orchestration='compose'
export var_load_general__toolbox_service='toolbox'
export var_load_general__script_dir="$tmp_dir"
export var_load_general__script_env_file='remote.sh'

if [ "${var_load_main__local:-}" = 'true' ]; then
	export var_load_general__script_env_file='local.sh'
fi

export var_load__db_main__db_host="${var_load__db_main__db_host:-elasticsearch}"
export var_load__db_main__db_port="${var_load__db_main__db_port:-9200}"

function tmp_error {
	echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}" >&2
	exit 2
}

tmp_errors=()

# specific vars...

tmp_is_db=''

if [ "${var_load_main__pod_type:-}" = 'app' ] || [ "${var_load_main__pod_type:-}" = 'db' ]; then
	tmp_is_db='true'
fi

if [ "$tmp_is_db" = 'true' ]; then
	if [ "${var_load_enable__custom_db_backup:-}" = 'true' ]; then
		tmp_db_dir='/tmp/main/elasticsearch/snapshots'
		tmp_db_repository_name="${var_load__db_backup__repository_name:-efk_repository}"
		tmp_default_snapshot_name='<snapshot-{now/d{yyyyMMdd}}-{now/s{HHmmss}}>'
		tmp_db_snapshot_name="${var_load__db_backup__snapshot_name:-$tmp_default_snapshot_name}"

		tmp_is_compressed_file="${var_load__db_backup__is_compressed_file:-}"

		if [ "${var_load__db_backup__use_s3:-}" = 'true' ]; then
			tmp_db_subtask_cmd_local=''
			tmp_db_subtask_cmd_remote='backup:db'
			tmp_db_snapshot_type="${var_load__db_backup__snapshot_type:-s3}"
		else
			tmp_db_subtask_cmd_local='backup:db'
			tmp_db_subtask_cmd_remote=''
			tmp_db_snapshot_type="${var_load__db_backup__snapshot_type:-fs}"
		fi

		export var_task__db_backup__task__type='backup'
		export var_task__db_backup__backup_task__subtask_cmd_local="$tmp_db_subtask_cmd_local"
		export var_task__db_backup__backup_task__subtask_cmd_remote="$tmp_db_subtask_cmd_remote"
		export var_task__db_backup__backup_task__is_compressed_file="$tmp_is_compressed_file"

		if [ "${var_load__db_backup__use_s3:-}" = 'true' ] && [ "$tmp_is_compressed_file" = 'true' ]; then
			tmp_errors+=("db_backup - use_s3 and is_compressed_file are both true")
		elif [ "$tmp_is_compressed_file" = 'true' ]; then
			tmp_compress_type="${var_load__db_backup__db_compress_type:-zip}"
			tmp_default_compress_file_name='efk.[[ datetime ]].[[ random ]].zip'
			tmp_compress_file_name="${var_load__db_backup__db_compress_file_name:-$tmp_default_compress_file_name}"
			tmp_base_path='/tmp/main/tmp/backup/elasticsearch/'
			tmp_compress_dest_file="$tmp_base_path/$tmp_compress_file_name"

			export var_task__db_backup__backup_task__compress_type="$tmp_compress_type"
			export var_task__db_backup__backup_task__compress_dest_file="$tmp_compress_dest_file"
			export var_task__db_backup__backup_task__compress_pass="${var_load__db_backup__compress_pass:-}"

			export var_task__db_backup__backup_task__backup_date_format="${var_load__db_backup__backup_date_format:-}"
			export var_task__db_backup__backup_task__backup_time_format="${var_load__db_backup__backup_time_format:-}"
			export var_task__db_backup__backup_task__backup_datetime_format="${var_load__db_backup__backup_datetime_format:-}"
			export var_task__db_backup__backup_task__recursive_dir="${var_load__db_backup__recursive_dir:-}"
			export var_task__db_backup__backup_task__recursive_mode="${var_load__db_backup__recursive_mode:-}"
			export var_task__db_backup__backup_task__recursive_mode_dir="${var_load__db_backup__recursive_mode_dir:-}"
			export var_task__db_backup__backup_task__recursive_mode_file="${var_load__db_backup__recursive_mode_file:-}"
			export var_task__db_backup__backup_task__file_to_clear="${var_load__db_backup__file_to_clear:-}"
			export var_task__db_backup__backup_task__dir_to_clear="${var_load__db_backup__dir_to_clear:-}"
		fi

		export var_task__db_backup__backup_db__task_name='db_main'
		export var_task__db_backup__backup_db__db_subtask_cmd='db:backup:elasticsearch'
		export var_task__db_backup__backup_db__db_task_base_dir="$tmp_db_dir"
		export var_task__db_backup__backup_db__repository_name="$tmp_db_repository_name"
		export var_task__db_backup__backup_db__snapshot_name="$tmp_db_snapshot_name"
		export var_task__db_backup__backup_db__snapshot_type="$tmp_db_snapshot_type"
	fi


	if [ "${var_load_enable__custom_db_setup:-}" = 'true' ]; then
		if [ -z "${var_load__db_setup__snapshot_name:-}" ]; then
			tmp_errors+=("var_load__db_setup__snapshot_name is not defined")
		fi

		tmp_default_file_to_skip='/tmp/main/setup/db.skip'
		tmp_file_to_skip="${var_load__db_setup__verify_file_to_skip:-$tmp_default_file_to_skip}"

		tmp_db_base_dir='/tmp/main/elasticsearch'
		tmp_db_dir="$tmp_db_base_dir/snapshots"
		tmp_db_repository_name="${var_load__db_setup__repository_name:-efk_repository}"
		tmp_db_snapshot_name="${var_load__db_setup__snapshot_name:-}"
		tmp_default_index_prefix='fluentd-'
		tmp_db_index_prefix="${var_load__db_setup__index_prefix:-$tmp_default_index_prefix}"
		tmp_restore_remote_file="${var_load__db_setup__restore_remote_file:-}"
		export var_task__db_setup__setup_db__db_args="${var_load__db_setup__db_args:-}"

		if [ "${var_load__db_setup__use_s3:-}" = 'true' ]; then
			tmp_db_subtask_cmd_local=''
			tmp_db_subtask_cmd_remote='setup:db'
			tmp_db_snapshot_type="${var_load__db_setup__snapshot_type:-s3}"
		else
			tmp_db_subtask_cmd_local='setup:db'
			tmp_db_subtask_cmd_remote=''
			tmp_db_snapshot_type="${var_load__db_setup__snapshot_type:-fs}"

			if [ -n "$tmp_restore_remote_file" ]; then
				tmp_db_subtask_cmd_remote='setup:remote:default'
			fi
		fi

		export var_task__db_setup__task__type="setup"
		export var_task__db_setup__setup_task__verify_file_to_skip="$tmp_file_to_skip"
		export var_task__db_setup__setup_task__subtask_cmd_verify='setup:verify:db'
		export var_task__db_setup__setup_task__subtask_cmd_remote="$tmp_db_subtask_cmd_remote"
		export var_task__db_setup__setup_task__subtask_cmd_local="$tmp_db_subtask_cmd_local"

		export var_task__db_setup__setup_verify__db_subtask_cmd='db:restore:verify:elasticsearch'
		export var_task__db_setup__setup_verify__task_name="db_main"
		export var_task__db_setup__setup_verify__db_index_prefix="$tmp_db_index_prefix"

		export var_task__db_setup__setup_db__task_name='db_main'
		export var_task__db_setup__setup_db__db_subtask_cmd='db:restore:elasticsearch'
		export var_task__db_setup__setup_db__db_task_base_dir="$tmp_db_dir"
		export var_task__db_setup__setup_db__repository_name="$tmp_db_repository_name"
		export var_task__db_setup__setup_db__snapshot_name="$tmp_db_snapshot_name"
		export var_task__db_setup__setup_db__snapshot_type="$tmp_db_snapshot_type"
		export var_task__db_setup__setup_db__db_args="${var_load__db_setup__db_args:-}"

		export var_task__db_setup__setup_remote__restore_use_s3="${var_load__db_setup__use_s3:-false}"

		if [ "${var_load__db_setup__use_s3:-}" = 'true' ] && [ -n "$tmp_restore_remote_file" ]; then
			tmp_errors+=("db_setup - use_s3 is true and restore_remote_file is defined")
		elif [ -n "$tmp_restore_remote_file" ]; then
			tmp_db_compress_type="${var_load__db_setup__db_compress_type:-zip}"
			tmp_default_file_name='efk.zip'
			tmp_db_compress_file_name="${var_load__db_setup__db_compress_file_name:-$tmp_default_file_name}"
			tmp_base_path='/tmp/main/tmp/restore/elasticsearch/'
			tmp_db_compress_file="$tmp_base_path/$tmp_db_compress_file_name"

			export var_task__db_setup__setup_task__is_compressed_file="true"
			export var_task__db_setup__setup_task__compress_type="$tmp_db_compress_type"
			export var_task__db_setup__setup_task__compress_src_file="$tmp_db_compress_file"
			export var_task__db_setup__setup_task__compress_dest_dir="$tmp_db_base_dir"
			export var_task__db_setup__setup_task__compress_pass="${var_load__db_setup__compress_pass:-}"

			export var_task__db_setup__setup_remote__restore_dest_file="$tmp_db_compress_file"
			export var_task__db_setup__setup_remote__restore_remote_file="$tmp_restore_remote_file"
		fi
	fi
fi

tmp_error_count=${#tmp_errors[@]}

if [[ $tmp_error_count -gt 0 ]]; then
	for (( i=1; i<tmp_error_count+1; i++ )); do
		echo "$i/${tmp_error_count}: ${tmp_errors[$i-1]}" >&2
	done
fi

tmp_error_count_aux="$tmp_error_count"
tmp_error_count=0

# shellcheck disable=SC1090
. "$tmp_pod_layer_dir/shared/scripts/shared.vars.sh"

tmp_shared_error_count="${tmp_error_count:-0}"

tmp_final_error_count=$((tmp_error_count_aux + tmp_shared_error_count))

if [[ $tmp_final_error_count -gt 0 ]]; then
	tmp_error "$tmp_final_error_count error(s) when loading the variables"
fi