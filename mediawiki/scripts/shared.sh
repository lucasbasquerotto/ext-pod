#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

pod_layer_dir="$var_pod_layer_dir"
pod_script_env_file="$var_pod_script"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}"
}

[ "${var_run__meta__no_stacktrace:-}" != 'true' ] \
	&& trap 'echo "[error] ${BASH_SOURCE[0]}:$LINENO"; exit $LINENO;' ERR

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env)."
fi

shift;

args=("$@")

# shellcheck disable=SC2214
while getopts ':-:' OPT; do
	if [ "$OPT" = "-" ]; then     # long option: reformulate OPT and OPTARG
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

pod_shared_run_file="$pod_layer_dir/shared/scripts/main.sh"

case "$command" in
	"prepare")
		data_dir="/var/main/data"

		"$pod_script_env_file" up "$var_run__general__toolbox_service"

		"$pod_script_env_file" exec-nontty "$var_run__general__toolbox_service" /bin/bash <<-SHELL || error "$command"
			if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "web" ]; then
				dir="$data_dir/mediawiki/uploads"

				if [ ! -d "\$dir" ]; then
					mkdir -p "\$dir"
				fi

				chown -R 33:33 "\$dir"

				dir="$data_dir/tmp/log/mediawiki"

				if [ ! -d "\$dir" ]; then
					mkdir -p "\$dir"
					chmod 777 "\$dir"
				fi
			fi
		SHELL

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"migrate")
		if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
			"$pod_shared_run_file" up mysql
		fi

		if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "web" ]; then
			"$pod_shared_run_file" up mediawiki

			info "$command - verify the need to setup the mediawiki database"
			count="$("$pod_script_env_file" "migrate:db:table:count")"

			if [ "$count" = "0" ]; then
				info "$command - setup the mediawiki database..."
				"$pod_shared_run_file" exec-nontty mediawiki php maintenance/upgrade.php
			else
				>&2 echo "skipping..."
			fi
		fi

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"migrate:db:table:count")
		db_service="mysql"
		db_cmd=""
		db_host="$var_run__migrate__db_host"
		db_port="$var_run__migrate__db_port"
		db_remote=""

		if [ "$var_custom__pod_type" != "app" ] && [ "$var_custom__pod_type" != "db" ]; then
			db_service="mysql_cli"
			db_cmd="run"
			db_remote="true"
		fi

		"$pod_shared_run_file" "run:db:main:tables:count:mysql" \
			--db_service="$db_service" \
			--db_cmd="$db_cmd" \
			--db_host="$db_host" \
			--db_port="$db_port" \
			--db_name="$var_run__migrate__db_name" \
			--db_user="$var_run__migrate__db_user" \
			--db_pass="$var_run__migrate__db_pass" \
			--db_remote="$db_remote" \
			--db_connect_wait_secs="$var_run__migrate__db_connect_wait_secs" \
			--connection_sleep="${var_run__migrate__connection_sleep:-}"
		;;
	"custom:unique:log")
		opts=()
		opts+=( 'log_register.memory_overview' )
		opts+=( 'log_register.memory_details' )
		opts+=( 'log_register.entropy' )

		if [ "${var_custom__use_nginx:-}" = "true" ]; then
			opts+=( 'log_register.nginx_basic_status' )
		fi

		"$pod_script_env_file" "unique:all" "${opts[@]}"
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

			if [ "${var_custom__use_haproxy:-}" = "true" ]; then
				"$pod_script_env_file" "shared:log:haproxy:summary" --days_ago="$days_ago" --max_amount="$max_amount"
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
	*)
		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
esac