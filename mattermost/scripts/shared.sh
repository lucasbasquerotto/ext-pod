#!/bin/bash
set -eou pipefail

# shellcheck disable=SC2154
pod_layer_dir="$var_pod_layer_dir"
# shellcheck disable=SC2154
pod_script_env_file="$var_pod_script"
# shellcheck disable=SC2154
inner_run_file="$var_inner_scripts_dir/run"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}"
}

[ "${var_run__meta__no_stacktrace:-}" != 'true' ] \
	&& trap 'echo "[error] ${BASH_SOURCE[0]}:$LINENO" >&2; exit 3;' ERR

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
		pod_type ) arg_pod_type="${OPTARG:-}";;
		use_pgadmin ) arg_use_pgadmin="${OPTARG:-}";;
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
		pod_type="${var_main__pod_type:-}"
		use_pgadmin="${var_main__use_pgadmin:-}"

		env_dir="/var/main/env"
		data_dir="/var/main/data"

		"$pod_script_env_file" up toolbox

		"$pod_script_env_file" exec-nontty toolbox \
			bash "$inner_run_file" "inner:custom:prepare" \
			--pod_type="$pod_type" \
			--use_pgadmin="$use_pgadmin"

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"inner:custom:prepare")
		env_dir="/var/main/env"
		data_dir="/var/main/data"

		if [ "$arg_pod_type" = "app" ] || [ "$arg_pod_type" = "web" ]; then
			file="$env_dir/mattermost/config.json"
			chown 2000:2000 "$file"

			dir="$data_dir/mattermost/uploads"

			if [ ! -d "$dir" ]; then
				mkdir -p "$dir"
			fi

			chown 2000:2000 "$dir"

			if [ "${arg_use_pgadmin:-}" = 'true' ]; then
				src_file="$data_dir/secrets/pgadmin_pass.txt"
				dest_dir="$data_dir/pgadmin/secrets"
				dest_file="$dest_dir/pgadmin_pass"

				if [ ! -d "$dest_dir" ]; then
					mkdir -p "$dest_dir"
				fi

				chown 5050:5050 "$dest_dir"

				cp "$src_file" "$dest_file"
				chown 5050:5050 "$dest_file"
				chmod 600 "$dest_file"
			fi
		fi
		;;
	"setup")
		# shellcheck disable=SC2154
		pod_type="$var_main__pod_type"

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}

		"$pod_script_env_file" exec-nontty toolbox \
			bash "$inner_run_file" "inner:custom:setup" \
			--pod_type="$pod_type"
		;;
	"inner:custom:setup")
		data_dir="/var/main/data"

		if [ "$arg_pod_type" = "app" ] || [ "$arg_pod_type" = "web" ]; then
			dir="$data_dir/mattermost/uploads"
			chown -R 2000:2000 "$dir"
		fi
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
		days_ago="${var_log__summary__days_ago:-}"
		days_ago="${arg_days_ago:-$days_ago}"

		max_amount="${var_log__summary__max_amount:-}"
		max_amount="${arg_max_amount:-$max_amount}"
		max_amount="${max_amount:-100}"

		"$pod_script_env_file" "shared:log:memory_overview:summary" --days_ago="$days_ago" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:entropy:summary" --days_ago="$days_ago" --max_amount="$max_amount"

		if [ "$var_main__pod_type" = "app" ] || [ "$var_main__pod_type" = "web" ]; then
			if [ "${var_main__use_nginx:-}" = "true" ]; then
				"$pod_script_env_file" "shared:log:nginx:summary" --days_ago="$days_ago" --max_amount="$max_amount"
				"$pod_script_env_file" "shared:log:nginx:summary:connections" --days_ago="$days_ago" --max_amount="$max_amount"
			fi

			if [ "${var_main__use_haproxy:-}" = "true" ]; then
				"$pod_script_env_file" "shared:log:haproxy:summary" --days_ago="$days_ago" --max_amount="$max_amount"
			fi
		fi

		"$pod_script_env_file" "shared:log:file_descriptors:summary" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:disk:summary" \
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
	*)
		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
esac