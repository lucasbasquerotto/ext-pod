#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

pod_layer_dir="$var_pod_layer_dir"
pod_script_env_file="$var_pod_script"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
}

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
	"action:exec:actions")
		"$pod_script_env_file" "shared:action:log_register.memory_overview" > /dev/null 2>&1 ||:
		"$pod_script_env_file" "shared:action:log_register.memory_details" > /dev/null 2>&1 ||:
		"$pod_script_env_file" "shared:action:log_register.entropy" > /dev/null 2>&1 ||:

		if [ "${var_custom__use_haproxy:-}" = "true" ]; then
			"$pod_script_env_file" "shared:action:log_register.haproxy_basic_status" > /dev/null 2>&1 ||:
			"$pod_script_env_file" "shared:action:haproxy_reload" > /dev/null 2>&1 ||:
		elif [ "${var_custom__use_nginx:-}" = "true" ]; then
			"$pod_script_env_file" "shared:action:log_register.nginx_basic_status" > /dev/null 2>&1 ||:
			"$pod_script_env_file" "shared:action:nginx_reload" > /dev/null 2>&1 ||:
		fi

		if [ "${var_custom__use_haproxy:-}" = "true" ] || [ "${var_custom__use_nginx:-}" = "true" ]; then
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

		if [ "${var_custom__use_haproxy:-}" = "true" ]; then
			"$pod_script_env_file" "shared:log:haproxy:summary" --days_ago="$days_ago" --max_amount="$max_amount"
			"$pod_script_env_file" "shared:log:haproxy:summary:connections" --days_ago="$days_ago" --max_amount="$max_amount"
		elif [ "${var_custom__use_nginx:-}" = "true" ]; then
			"$pod_script_env_file" "shared:log:nginx:summary" --days_ago="$days_ago" --max_amount="$max_amount"
			"$pod_script_env_file" "shared:log:nginx:summary:connections" --days_ago="$days_ago" --max_amount="$max_amount"
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