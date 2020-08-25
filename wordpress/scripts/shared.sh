#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

# shellcheck disable=SC2153
pod_vars_dir="$POD_VARS_DIR"
# shellcheck disable=SC2153
pod_layer_dir="$POD_LAYER_DIR"
# shellcheck disable=SC2153
pod_script_env_file="$POD_SCRIPT_ENV_FILE"

# shellcheck disable=SC1090
. "${pod_vars_dir}/vars.sh"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
}

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env - shared)."
fi

shift;

args=("$@")

# shellcheck disable=SC2214
while getopts ':-:' OPT; do
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		days_ago ) arg_days_ago="${OPTARG:-}";;
		max_amount ) arg_max_amount="${OPTARG:-}";;
		??* ) ;; ## ignore
		\? )  ;; ## ignore
	esac
done
shift $((OPTIND-1))

pod_env_shared_exec_file="$pod_layer_dir/$var_run__general__script_dir/shared.exec.sh"
pod_shared_run_file="$pod_layer_dir/$var_shared__script_dir/main.sh"

case "$command" in
	"prepare")
		data_dir="/var/main/data"

		"$pod_script_env_file" up toolbox

		"$pod_script_env_file" exec-nontty "$var_run__general__toolbox_service" /bin/bash <<-SHELL || error "$command"
			set -eou pipefail

			if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "web" ]; then
				dir="$data_dir/wordpress/uploads"

				if [ ! -d "\$dir" ]; then
					mkdir -p "\$dir"
					chmod 777 "\$dir"
				fi
			fi
		SHELL

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"migrate")
		opts=()

		opts+=( "--old_domain_host=${var_run__migrate__old_domain_host:-}" )
		opts+=( "--new_domain_host=${var_run__migrate__new_domain_host:-}" )
		opts+=( "--wp_rewrite_structure=${var_run__migrate__wp_rewrite_structure:-}" )
		opts+=( "--use_w3tc=${var_run__migrate__use_w3tc:-}" )
		opts+=( "--use_varnish=${var_run__migrate__use_varnish:-}" )
		opts+=( "--use_redis=${var_run__migrate__use_redis:-}" )
		opts+=( "--use_memcached=${var_run__migrate__use_memcached:-}" )

		"$pod_env_shared_exec_file" "migrate:$var_custom__pod_type" "${opts[@]}"

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
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
	"action:exec:actions")
		"$pod_script_env_file" "shared:action:log_register.memory_overview" > /dev/null 2>&1 ||:
		"$pod_script_env_file" "shared:action:log_register.memory_details" > /dev/null 2>&1 ||:
		"$pod_script_env_file" "shared:action:log_register.entropy" > /dev/null 2>&1 ||:

		if [ "${var_custom__use_nginx:-}" = "true" ]; then
			"$pod_script_env_file" "shared:action:log_register.nginx_basic_status" > /dev/null 2>&1 ||:
			"$pod_script_env_file" "shared:action:nginx_reload" > /dev/null 2>&1 ||:
			"$pod_script_env_file" "shared:action:block_ips" > /dev/null 2>&1 ||:
		fi

		"$pod_script_env_file" "shared:action:logrotate" > /dev/null 2>&1 ||:
		"$pod_script_env_file" "shared:action:log_summary" > /dev/null 2>&1 ||:
		"$pod_script_env_file" "shared:action:backup" > /dev/null 2>&1 ||:
		;;
	"action:exec:log_summary")
        days_ago="${var_custom__log_summary__days_ago:-}"
        days_ago="${arg_days_ago:-$days_ago}"

        max_amount="${var_custom__log_summary__max_amount:-}"
        max_amount="${arg_max_amount:-$max_amount}"
        max_amount="${max_amount:-100}"

		"$pod_script_env_file" "shared:log:memory_overview:summary" --days_ago="$days_ago" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:entropy:summary" --days_ago="$days_ago" --max_amount="$max_amount"

		if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "web" ]; then
			if [ "${var_custom__use_nginx:-}" = "true" ]; then
				"$pod_script_env_file" "shared:log:nginx:summary" --days_ago="$days_ago" --max_amount="$max_amount"
				"$pod_script_env_file" "shared:log:nginx:summary:connections" --days_ago="$days_ago" --max_amount="$max_amount"
			fi
		fi

		if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
			"$pod_script_env_file" "shared:log:mysql_slow:summary" --days_ago="$days_ago" --max_amount="$max_amount"
		fi

		"$pod_script_env_file" "shared:log:file_descriptors:summary" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:disk:summary" \
			--verify_size_docker_dir="${var_custom__log_summary__verify_size_docker_dir:-}" \
			--verify_size_containers="${var_custom__log_summary__verify_size_containers:-}"
		;;
	*)
		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
esac
