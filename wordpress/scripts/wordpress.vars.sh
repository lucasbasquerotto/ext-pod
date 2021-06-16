#!/bin/bash
set -eou pipefail

tmp_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2154
tmp_pod_layer_dir="$var_pod_layer_dir"

export var_load_name='wordpress'
export var_load_main__db_service='mysql'
export var_load_main__db_backup_task="db:main:${var_load_main__db_service:-}:backup:file"
export var_load_main__db_restore_task="db:main:${var_load_main__db_service:-}:restore:file"
export var_load_main__db_backup_is_file='true'

export var_load_general__orchestration='compose'
export var_load_general__toolbox_service='toolbox'
export var_load_general__script_dir="$tmp_dir"
export var_load_general__script_env_file='remote.sh'

if [ "${var_load_main__local:-}" = 'true' ]; then
	export var_load_general__script_env_file='local.sh'
fi

function tmp_error {
	echo "${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}" >&2
	exit 2
}

tmp_errors=()

# specific vars...

tmp_is_web=''

if [ "${var_load_main__pod_type:-}" = 'app' ] || [ "${var_load_main__pod_type:-}" = 'web' ]; then
	tmp_is_web='true'
fi

export var_main__use_s3_storage="${var_load_use__s3_storage:-}"
export var_main__use_composer="${var_load_use__composer:-}"

export var_run__migrate__use_varnish="${var_load_use__varnish:-}"
export var_run__migrate__use_redis="${var_load_use__redis:-}"
export var_run__migrate__use_memcached="${var_load_use__memcached:-}"
export var_run__migrate__use_w3tc="${var_load_use__w3tc:-}"

export var_run__migrate__new_domain_host="${var_load_migrate__new_domain_host:-}"
export var_run__migrate__old_domain_host="${var_load_migrate__old_domain_host:-}"
export var_run__migrate__wp_rewrite_structure="${var_load_migrate__wp_rewrite_structure:-}"

if [ "$tmp_is_web" = 'true' ]; then
    export var_run__migrate__wp_activate_all_plugins="${var_load_migrate__wp_activate_all_plugins:-}"
    export var_run__migrate__wp_plugins_to_activate="${var_load_migrate__wp_plugins_to_activate:-}"
    export var_run__migrate__wp_plugins_to_deactivate="${var_load_migrate__wp_plugins_to_deactivate:-}"
fi

export var_custom__app_dev="${var_load_main__app_dev:-}"

if [ "${var_load_main__app_dev:-}" = 'true' ]; then
    export var_dev__repo_dir_wordpress="${var_load_main__repo_dir_wordpress:-}"
fi

if [ "$tmp_is_web" = 'true' ]; then
	if [ "${var_load_enable__db_setup_new:-}" = 'true' ]; then
		if [ "${var_load_enable__db_setup:-}" = 'true' ]; then
			tmp_errors+=("var_load_enable__db_setup and var_load_enable__db_setup_new are both true (choose only one)")
		fi

		if [ -z "${var_load_main__db_service:-}" ]; then
			tmp_errors+=("var_load_main__db_service is not defined (db_setup_new)")
		fi

		tmp_default_file_to_skip='/tmp/main/setup/db.skip'
		tmp_file_to_skip="${var_load__db_setup_new__verify_file_to_skip:-$tmp_default_file_to_skip}"

		export var_task__db_setup_new__task__type='setup'
		export var_task__db_setup_new__setup_task__setup_run_new_task='true'
		export var_task__db_setup_new__setup_task__subtask_cmd_new='setup:new'
		export var_task__db_setup_new__setup_task__verify_file_to_skip="$tmp_file_to_skip"
		export var_task__db_setup_new__setup_task__subtask_cmd_verify='shared:db:task:setup_verify'
		export var_task__db_setup_new__setup_verify__task_name='db_main'
		export var_task__db_setup_new__setup_verify__db_subtask_cmd="db:restore:verify:${var_load_main__db_service:-}"
		export var_task__db_setup_new__setup_new__admin_email="${var_load__db_setup_new__admin_email:-}"
		export var_task__db_setup_new__setup_new__admin_password="${var_load__db_setup_new__admin_password:-}"
		export var_task__db_setup_new__setup_new__admin_user="${var_load__db_setup_new__admin_user:-}"
		export var_task__db_setup_new__setup_new__remote_seed_data="${var_load__db_setup_new__remote_seed_data:-}"
		export var_task__db_setup_new__setup_new__restore_seed="${var_load__db_setup_new__restore_seed:-}"
		export var_task__db_setup_new__setup_new__title="${var_load__db_setup_new__title:-}"
		export var_task__db_setup_new__setup_new__url="${var_load__db_setup_new__url:-}"
	fi
fi

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