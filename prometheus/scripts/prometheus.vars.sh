#!/bin/bash
set -eou pipefail

tmp_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC2153
tmp_pod_layer_dir="$POD_LAYER_DIR"

export var_load_name='prometheus'
export var_load_db_service='prometheus'

export var_load_general__orchestration='compose'
export var_load_general__toolbox_service='toolbox'
export var_load_general__script_dir="$tmp_dir"
export var_load_general__script_env_file='remote.sh'

if [ "${var_load_main__local:-}" = 'true' ]; then
	export var_load_general__script_env_file='local.sh'
fi

export var_load__db_main__db_host="${var_load__db_main__db_host:-prometheus}"
export var_load__db_main__db_port="${var_load__db_main__db_port:-9090}"

function tmp_error {
	echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}" >&2
	exit 2
}

tmp_errors=()

# specific vars...

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