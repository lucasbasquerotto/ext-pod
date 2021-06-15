#!/bin/bash
set -eou pipefail

tmp_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2154
tmp_pod_layer_dir="$var_pod_layer_dir"

export var_load_name='mediawiki'
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