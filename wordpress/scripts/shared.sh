#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC1117,SC2153,SC2214
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_layer_dir="$POD_LAYER_DIR"

. "${pod_vars_dir}/vars.sh"

pod_env_shared_exec_file="$pod_layer_dir/$var_run__general__script_dir/shared.exec.sh"
pod_script_run_main_file="$pod_layer_dir/main/scripts/main.sh"

GRAY='\033[0;90m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function info {
	msg="$(date '+%F %T') - ${1:-}"
	>&2 echo -e "${GRAY}${msg}${NC}"
}

function error {
	msg="$(date '+%F %T') - ${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${1:-}"
	>&2 echo -e "${RED}${msg}${NC}"
	exit 2
}

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env - shared)."
fi

shift;

args=("$@")

case "$command" in
	"prepare")
		info "$command - do nothing..."
		;;
	"migrate")
		opts=()

		opts+=( "--old_domain_host=${var_run__migrate__old_domain_host:-}" )
		opts+=( "--new_domain_host=${var_run__migrate__new_domain_host:-}" )

		"$pod_env_shared_exec_file" "migrate:$var_custom__pod_type" "${opts[@]}"
		;;
	"migrate:"*)
		"$pod_env_shared_exec_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"setup:new")
		prefix="var_task__${arg_task_name}__setup_new_"

		url="${prefix}_url"
		title="${prefix}_title"
		admin_user="${prefix}_admin_user"
		admin_password="${prefix}_admin_password"
		admin_email="${prefix}_admin_email"
		restore_seed="${prefix}_restore_seed"
		local_seed_data="${prefix}_local_seed_data"
		remote_seed_data="${prefix}_remote_seed_data"

		opts=()

		opts+=( "--setup_url=${!url}" )
		opts+=( "--setup_title=${!title}" )
		opts+=( "--setup_admin_user=${!admin_user}" )
		opts+=( "--setup_admin_password=${!admin_password}" )
		opts+=( "--setup_admin_email=${!admin_email}" )

		opts+=( "--setup_restore_seed=${!restore_seed:-}" )
		opts+=( "--setup_local_seed_data=${!local_seed_data:-}" )
		opts+=( "--setup_remote_seed_data=${!remote_seed_data:-}" )

		"$pod_env_shared_exec_file" "$command" "${opts[@]}"
		;;
	*)
		"$pod_script_run_main_file" "$command" ${args[@]+"${args[@]}"}
		;;
esac
