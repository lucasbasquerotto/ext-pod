#!/bin/bash
set -eou pipefail

# shellcheck disable=SC2154
pod_layer_dir="$var_pod_layer_dir"
# shellcheck disable=SC2154
pod_script_env_file="$var_pod_script"
# shellcheck disable=SC2154
inner_run_file="$var_inner_scripts_dir/run"
# shellcheck disable=SC2154
pod_data_dir="$var_pod_data_dir"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}"
}

function warn {
	"$pod_script_env_file" "util:warn" --warn="${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}"
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
		use_internal_ssl ) arg_use_internal_ssl="${OPTARG:-}";;
		db_pass ) arg_db_pass="${OPTARG:-}";;
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

		data_dir="/var/main/data"
		tmp_dir="/tmp/main"

		"$pod_script_env_file" up toolbox

		"$pod_script_env_file" exec-nontty toolbox \
			bash "$inner_run_file" "inner:custom:prepare" \
				--pod_type="$pod_type" \
				--use_internal_ssl="${var_main__use_internal_ssl:-}"

		vm_max_map_count="${var_migrate_es_vm_max_map_count:-262144}"
		info "$command increasing vm max map count to $vm_max_map_count"
		sudo sysctl -w vm.max_map_count="$vm_max_map_count"

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"inner:custom:prepare")
		data_dir="/var/main/data"
		tmp_dir="/tmp/main"
		env_dir="/var/main/env"

		if [ "$arg_pod_type" = "app" ] || [ "$arg_pod_type" = "db" ]; then
			dir="$data_dir/elasticsearch"

			if [ ! -d "$dir" ]; then
				mkdir -p "$dir"
				chown 1000:1000 "$dir"
			fi

			dir="$tmp_dir/elasticsearch"

			if [ ! -d "$dir" ]; then
				mkdir -p "$dir"
				chown 1000:1000 "$dir"
			fi

			dir="$tmp_dir/elasticsearch/snapshots"

			if [ ! -d "$dir" ]; then
				mkdir -p "$dir"
				chown 1000:1000 "$dir"
			fi

			dir="$tmp_dir/secrets/elasticsearch"

			if [ ! -d "$dir" ]; then
				mkdir -p "$dir"
				chown 1000:1000 "$dir"
			fi

			touch "$dir/keystore.txt"

			if [ "${var_main__local:-}" = 'true' ]; then
				chmod 666 "$dir/keystore.txt"
			fi

			src_dir="$env_dir/ssl"
			dir="$tmp_dir/elasticsearch/ssl"

			if [ "${arg_use_internal_ssl:-}" = 'true' ]; then
				mkdir -p "$dir"
				cp -R --no-target-directory "$src_dir" "$dir"
				chown 1000:1000 "$dir"/*
			fi
		fi

		if [ "$arg_pod_type" = "app" ] || [ "$arg_pod_type" = "web" ]; then
			src_dir="$env_dir/ssl"
			dir="$tmp_dir/kibana/ssl"

			if [ "${arg_use_internal_ssl:-}" = 'true' ]; then
				mkdir -p "$dir"
				cp -R --no-target-directory "$src_dir" "$dir"
				chown 1000:1000 "$dir"/*
			fi
		fi
		;;
	"shared:setup")
		if [ "$var_main__pod_type" = "app" ] || [ "$var_main__pod_type" = "db" ]; then
			"$pod_script_env_file" "custom:elasticsearch:setup"
		fi

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"custom:elasticsearch:setup")
		"$pod_script_env_file" up toolbox elasticsearch

		"$pod_script_env_file" "db:subtask:db_main" --db_subtask_cmd="db:main:elasticsearch:ready"

		if [ "${var_main__use_secure_elasticsearch:-}" = 'true' ]; then
			db_pass="$("$pod_script_env_file" "db:subtask:db_main" --db_subtask_cmd="db:main:elasticsearch:pass")"

			"$pod_script_env_file" exec-nontty toolbox \
				bash "$inner_run_file" "inner:custom:elasticsearch:secure:main" \
				--db_pass="$db_pass"
		fi

		# Define Keystore
		if [ "${var_custom__s3_snapshot:-}" = 'true' ]; then
			keystore_file="$pod_layer_dir/env/elasticsearch/keystore.txt"
			keystore_tmp_file="$pod_data_dir/tmp/secrets/elasticsearch/keystore.txt"

			checksum1="$(md5sum "$keystore_file" | awk '{print $1}')"
			checksum2="$(md5sum "$keystore_tmp_file" | awk '{print $1}')"

			if [ "$checksum1" != "$checksum2" ]; then
				info "$command: add variables to the elasticsearch keystore"

				while IFS='=' read -r key value; do
					keystore_new_error='false'

					echo "$value" | xargs \
						| "$pod_script_env_file" exec-nontty elasticsearch \
							bin/elasticsearch-keystore add --stdin --force "$(echo "$key" | xargs)" \
							>&2 || keystore_new_error='true'

					if [ "$keystore_new_error" != 'false' ]; then
						error "error when adding the variable '$(echo "$key" | xargs)' to the keystore (possibly OOM error)"
					fi
				done < "$keystore_file"

				info "copying the backup keystore file..."
				cp "$keystore_file" "$keystore_tmp_file"

				"$pod_script_env_file" restart elasticsearch
			fi
		fi
		;;
	"inner:custom:elasticsearch:secure:main")
		echo "creating the elasticsearch roles..." >&2

		info "creating/updating role fluentd..."

		curl --fail -sS -u "elastic:$arg_db_pass" \
			--cacert /etc/ssl/fullchain.pem \
			-XPOST "https://elasticsearch:9200/_security/role/fluentd" \
			-d'{
				"cluster": ["manage_index_templates", "monitor", "manage_ilm"],
				"indices": [
					{
						"names": [ "fluentd-*" ],
						"privileges": ["write","create","delete","create_index","manage","manage_ilm"]
					}
				]
			}' \
			-H "Content-Type: application/json" \
			>&2

		echo "" >&2

		# Create Users
		info "creating the elasticsearch users..."

		while IFS='=' read -r key value; do
			user="$(echo "$key" | xargs)"

			if [ "$user" != 'elastic' ] && [[ ! "$user" == \#* ]]; then
				info "creating/updating user $user..."

				curl --fail -sS -u "elastic:$arg_db_pass" \
					--cacert /etc/ssl/fullchain.pem \
					-XPOST "https://elasticsearch:9200/_security/user/${user}" \
					-d"$value" \
					-H "Content-Type: application/json" \
					>&2
				echo ""
			fi
		done < "/var/main/env/elasticsearch/users.txt"
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