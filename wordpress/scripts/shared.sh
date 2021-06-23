#!/bin/bash
set -eou pipefail

# shellcheck disable=SC2154
pod_layer_dir="$var_pod_layer_dir"
# shellcheck disable=SC2154
pod_script_env_file="$var_pod_script"
# shellcheck disable=SC2154
pod_env_shared_exec_file="$var_run__general__script_dir/shared.exec.sh"
# shellcheck disable=SC2154
inner_run_file="$var_inner_scripts_dir/run"

pod_shared_run_file="$pod_layer_dir/shared/scripts/main.sh"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}"
}

[ "${var_run__meta__no_stacktrace:-}" != 'true' ] \
	&& trap 'echo "[error] ${BASH_SOURCE[0]}:$LINENO" >&2; exit $LINENO;' ERR

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
		pod_type ) arg_pod_type="${OPTARG:-}";;
		task_info ) arg_task_info="${OPTARG:-}";;
		task_name ) arg_task_name="${OPTARG:-}";;
		days_ago ) arg_days_ago="${OPTARG:-}";;
		max_amount ) arg_max_amount="${OPTARG:-}";;
		??* ) ;; ## ignore
		\? )  ;; ## ignore
	esac
done
shift $((OPTIND-1))

title=''
[ -n "${arg_task_info:-}" ] && title="${arg_task_info:-} > "
title="${title}${command}"

case "$command" in
	"prepare")
		# shellcheck disable=SC2154
		pod_type="$var_main__pod_type"

		"$pod_script_env_file" up toolbox

		"$pod_script_env_file" exec-nontty toolbox \
			"$inner_run_file" "inner:custom:prepare" \
			--pod_type="$pod_type"

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"inner:custom:prepare")
		data_dir="/var/main/data"

		if [ "$arg_pod_type" = "app" ] || [ "$arg_pod_type" = "web" ]; then
			dir="$data_dir/wordpress/uploads"

			if [ ! -d "$dir" ]; then
				mkdir -p "$dir"
			fi

			chown -R 33:33 "$dir"
		fi
		;;
	"migrate")
		# shellcheck disable=SC2154
		pod_type="$var_main__pod_type"

		opts=()

		opts+=( "--wp_activate_all_plugins=${var_run__migrate__wp_activate_all_plugins:-}" )
		opts+=( "--wp_plugins_to_activate=${var_run__migrate__wp_plugins_to_activate:-}" )
		opts+=( "--wp_plugins_to_deactivate=${var_run__migrate__wp_plugins_to_deactivate:-}" )
		opts+=( "--old_domain_host=${var_run__migrate__old_domain_host:-}" )
		opts+=( "--new_domain_host=${var_run__migrate__new_domain_host:-}" )
		opts+=( "--wp_rewrite_structure=${var_run__migrate__wp_rewrite_structure:-}" )
		opts+=( "--use_w3tc=${var_run__migrate__use_w3tc:-}" )
		opts+=( "--use_varnish=${var_run__migrate__use_varnish:-}" )
		opts+=( "--use_redis=${var_run__migrate__use_redis:-}" )
		opts+=( "--use_memcached=${var_run__migrate__use_memcached:-}" )
		opts+=( "--use_s3_storage=${var_main__use_s3_storage:-}" )

		"$pod_env_shared_exec_file" "migrate:$pod_type" "${opts[@]}"

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"migrate:"*|"inner:migrate:"*)
		"$pod_env_shared_exec_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"setup:new")
		prefix="var_task__${arg_task_name}__setup_new_"

		param_url="${prefix}_url"
		param_title="${prefix}_title"
		param_admin_user="${prefix}_admin_user"
		param_admin_password="${prefix}_admin_password"
		param_admin_email="${prefix}_admin_email"
		param_restore_seed="${prefix}_restore_seed"
		param_local_seed_data="${prefix}_local_seed_data"
		param_remote_seed_data="${prefix}_remote_seed_data"

		opts=( "--task_info=$title" )

		opts+=( "--setup_url=${!param_url}" )
		opts+=( "--setup_title=${!param_title}" )
		opts+=( "--setup_admin_user=${!param_admin_user}" )
		opts+=( "--setup_admin_password=${!param_admin_password}" )
		opts+=( "--setup_admin_email=${!param_admin_email}" )
		opts+=( "--setup_restore_seed=${!param_restore_seed:-}" )
		opts+=( "--setup_local_seed_data=${!param_local_seed_data:-}" )
		opts+=( "--setup_remote_seed_data=${!param_remote_seed_data:-}" )

		"$pod_env_shared_exec_file" "$command" "${opts[@]}"
		;;
	"custom:unique:log")
		opts=()
		opts+=( 'log_register.memory_overview' )
		opts+=( 'log_register.memory_details' )
		opts+=( 'log_register.entropy' )

		if [ "${var_main__use_nginx:-}" = "true" ]; then
			opts+=( 'log_register.nginx_basic_status' )
		fi

		"$pod_script_env_file" "unique:all" "${opts[@]}"
		;;
	"action:exec:log_summary")
		# shellcheck disable=SC2154
		pod_type="$var_main__pod_type"

		days_ago="${var_log__summary__days_ago:-}"
		days_ago="${arg_days_ago:-$days_ago}"

		max_amount="${var_log__summary__max_amount:-}"
		max_amount="${arg_max_amount:-$max_amount}"
		max_amount="${max_amount:-100}"

		"$pod_script_env_file" "shared:log:memory_overview:summary" --task_info="$title" --days_ago="$days_ago" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:entropy:summary" --task_info="$title" --days_ago="$days_ago" --max_amount="$max_amount"

		if [ "$pod_type" = "app" ] || [ "$pod_type" = "web" ]; then
			if [ "${var_main__use_nginx:-}" = "true" ]; then
				"$pod_script_env_file" "shared:log:nginx:summary" --task_info="$title" --days_ago="$days_ago" --max_amount="$max_amount"
				"$pod_script_env_file" "shared:log:nginx:summary:connections" --task_info="$title" --days_ago="$days_ago" --max_amount="$max_amount"
			fi

			if [ "${var_main__use_haproxy:-}" = "true" ]; then
				"$pod_script_env_file" "shared:log:haproxy:summary" --days_ago="$days_ago" --max_amount="$max_amount"
			fi
		fi

		if [ "$pod_type" = "app" ] || [ "$pod_type" = "db" ]; then
			"$pod_script_env_file" "shared:log:mysql_slow:summary" --task_info="$title" --days_ago="$days_ago" --max_amount="$max_amount"
		fi

		"$pod_script_env_file" "shared:log:file_descriptors:summary" --task_info="$title" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:disk:summary" \
			--task_info="$title" \
			--verify_size_docker_dir="${var_log__summary__verify_size_docker_dir:-}" \
			--verify_size_containers="${var_log__summary__verify_size_containers:-}"
		;;
	"shared:action:"*)
		action="${command#shared:action:}"

		case "$action" in
			"backup"|\
			"block_ips"|\
			"local.backup"|\
			"log_register.entropy"|\
			"log_register.memory_details"|\
			"log_register.memory_overview"|\
			"log_register.nginx_basic_status"|\
			"log_summary"|\
			"logrotate"|\
			"nginx_reload"|\
			"pending"|\
			"replicate_s3"|\
			"watch")
				"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
				;;
			*)
				error "$command: unsupported action: $action"
				;;
		esac
		;;
	"inner:setup:new:"*)
		"$pod_env_shared_exec_file" "$command" ${args[@]+"${args[@]}"}
		;;
	*)
		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
esac
