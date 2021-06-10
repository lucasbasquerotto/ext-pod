#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2153,SC2214
set -eou pipefail

pod_layer_dir="$var_pod_layer_dir"
pod_script_env_file="$var_pod_script"
pod_data_dir="$var_pod_data_dir"

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
	"build")
		bind_data_dir="$pod_data_dir/sync/bind"

		bind_zone_file="$bind_data_dir/$var_custom__bind__type/$var_custom__bind__zone"
		bind_zone_dir="$(dirname "$bind_zone_file")"

		if [ ! -f "$bind_zone_file" ]; then
			mkdir -p "$bind_zone_dir"
			cp "$pod_layer_dir/env/bind/zone.conf" "$bind_zone_file"
		fi

		"$pod_shared_run_file" "$command" "$@"
		;;
	"up")
		if [ "${var_custom__bind__external_port:-}" = '53' ]; then
			result="$(ps --no-headers -o comm 1)"

			if [ "$result" = "systemd" ]; then
				sudo systemctl stop systemd-resolved || :
			fi
		fi

		"$pod_shared_run_file" "$command" "$@"
		;;
	"new-key")
		"$pod_script_env_file" run dnssec bash <<-SHELL || error "$command"
			set -eou pipefail

			>&2 rm -rf /tmp/main/bind/keys
			>&2 mkdir -p /tmp/main/bind/keys

			cd /tmp/main/bind/keys
			>&2 dnssec-keygen -C -a HMAC-MD5 -b 512 -n USER "$var_custom__bind_zone".
			>&2 file_name="\$(ls -rt | grep "$var_custom__bind_zone" | tail -n1)"
			>&2 new_key="\$(cat "\$file_name" | awk '{ print \$7 }')"
			echo "\$new_key"
		SHELL
		;;
	"print-new-key")
		new_key="$("$pod_script_env_file" "new-key")"
		echo "new_key=$new_key"
		;;
	"bind:"*)
		ctx="${command#bind:}"
		prefix="var_bind_${ctx}"
		zone_name="${prefix}_zone_name"

		"$pod_script_env_file" exec-nontty toolbox <<-SHELL || error "$command"
			rm -rf /tmp/main/bind/keys
			mkdir /tmp/main/bind/keys
		SHELL

		"$pod_script_env_file" run dnssec <<-SHELL || error "$command"
			cd /tmp/main/bind/keys
			dnssec-keygen -a NSEC3RSASHA1 -b 2048 -n ZONE "$zone_name"
			dnssec-keygen -f KSK -a NSEC3RSASHA1 -b 4096 -n ZONE "$zone_name"

			for key in \$(ls K"$zone_name"*.key)
			do
				echo "\\\$INCLUDE \$key" >> "$zone_name".zone
			done

			salt="\$(head -c 1000 /dev/random | sha1sum | cut -b 1-16)"
			dnssec-signzone -3 "\$salt" -A -N INCREMENT -o "$zone_name" -t "$zone_name".zone
		SHELL
		;;
	"custom:unique:log")
		opts=()
		opts+=( 'log_register.memory_overview' )
		opts+=( 'log_register.memory_details' )
		opts+=( 'log_register.entropy' )

		if [ "$var_main__pod_type" = "app" ] || [ "$var_main__pod_type" = "web" ]; then
			if [ "${var_main__use_nginx:-}" = "true" ]; then
				opts+=( 'log_register.nginx_basic_status' )
			fi
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
		fi

		"$pod_script_env_file" "shared:log:file_descriptors:summary" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:disk:summary" \
			--verify_size_docker_dir="${var_log__summary__verify_size_docker_dir:-}" \
			--verify_size_containers="${var_log__summary__verify_size_containers:-}"
		;;
	"action:exec:bind_reload")
		"$pod_shared_run_file" exec-nontty bind rndc freeze "$var_custom__bind__zone"
		"$pod_shared_run_file" exec-nontty bind rndc reload "$var_custom__bind__zone"
		"$pod_shared_run_file" exec-nontty bind rndc thaw "$var_custom__bind__zone"
		;;
	"shared:action:"*)
		action="${command#shared:action:}"

		case "$action" in
			"backup"|\
			"bind_reload"|\
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