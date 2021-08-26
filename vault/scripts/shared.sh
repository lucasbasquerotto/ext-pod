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
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		pod_type ) arg_pod_type="${OPTARG:-}";;
		use_internal_ssl ) arg_use_internal_ssl="${OPTARG:-}";;
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
		# shellcheck disable=SC2154
		pod_type="$var_main__pod_type"

		"$pod_script_env_file" up toolbox > /dev/null

		"$pod_script_env_file" exec-nontty toolbox \
			bash "$inner_run_file" "inner:custom:prepare" \
				--pod_type="$pod_type" \
				--use_internal_ssl="${var_main__use_internal_ssl:-}"

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"inner:custom:prepare")
		data_dir="/var/main/data"
		tmp_dir="/tmp/main"
		env_dir="/var/main/env"

		base_dir="$data_dir/vault"

		dir="$base_dir/data"

		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		chown 100 "$dir"

		dir="$base_dir/logs"

		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		chown 100 "$dir"

		if [ "$arg_pod_type" = "app" ] || [ "$arg_pod_type" = "web" ]; then
			if [ "${arg_use_internal_ssl:-}" = 'true' ]; then
				src_dir="$env_dir/ssl"
				dir="$tmp_dir/vault/ssl"

				mkdir -p "$dir"
				cp -R --no-target-directory "$src_dir" "$dir"
				chown 100:1000 "$dir"/*
			fi
		fi

		if [ "$arg_pod_type" = "app" ] || [ "$arg_pod_type" = "db" ]; then
			if [ "${arg_use_internal_ssl:-}" = 'true' ]; then
				src_dir="$env_dir/ssl"
				dir="$tmp_dir/consul/ssl"

				mkdir -p "$dir"
				cp -R --no-target-directory "$src_dir" "$dir"
				chown 100:1000 "$dir"/*
			fi
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
		# shellcheck disable=SC2154
		pod_type="$var_main__pod_type"

		days_ago="${var_log__summary__days_ago:-}"
		days_ago="${arg_days_ago:-$days_ago}"

		max_amount="${var_log__summary__max_amount:-}"
		max_amount="${arg_max_amount:-$max_amount}"
		max_amount="${max_amount:-100}"

		"$pod_script_env_file" "shared:log:memory_overview:summary" --days_ago="$days_ago" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:entropy:summary" --days_ago="$days_ago" --max_amount="$max_amount"

		if [ "$pod_type" = "app" ] || [ "$pod_type" = "web" ]; then
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