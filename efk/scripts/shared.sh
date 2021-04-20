#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2153,SC2214
set -eou pipefail

pod_layer_dir="$var_pod_layer_dir"
pod_script_env_file="$var_pod_script"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}"
}

trap 'echo "[error] ${BASH_SOURCE[0]}:$LINENO"; exit $LINENO;' ERR

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env)."
fi

shift;

args=("$@")

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

pod_shared_run_file="$pod_layer_dir/shared/scripts/main.sh"

case "$command" in
	"prepare")
		data_dir="/var/main/data"
		tmp_dir="/tmp/main"

		"$pod_script_env_file" up toolbox

		"$pod_script_env_file" exec-nontty toolbox /bin/bash <<-SHELL || error "$command"
			if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
				dir="$data_dir/elasticsearch"

				if [ ! -d "\$dir" ]; then
					mkdir -p "\$dir"
					chown 1000:1000 "\$dir"
				fi

				dir="$tmp_dir/elasticsearch"

				if [ ! -d "\$dir" ]; then
					mkdir -p "\$dir"
					chown 1000:1000 "\$dir"
				fi

				dir="$tmp_dir/elasticsearch/snapshots"

				if [ ! -d "\$dir" ]; then
					mkdir -p "\$dir"
					chown 1000:1000 "\$dir"
				fi
			fi
		SHELL

		vm_max_map_count="${var_migrate_es_vm_max_map_count:-262144}"
		info "$command increasing vm max map count to $vm_max_map_count"
		sudo sysctl -w vm.max_map_count="$vm_max_map_count"

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"shared:setup")
		if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
			if [ "${var_custom__use_secure_elasticsearch:-}" = 'true' ]; then
				"$pod_script_env_file" "custom:elasticsearch:secure"
			fi
		fi

		"$pod_shared_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"custom:elasticsearch:secure")
		bootstrap_user='elastic'

		"$pod_script_env_file" up toolbox elasticsearch

		function bootstrap_password {
			"$pod_script_env_file" exec-nontty elasticsearch /bin/bash <<-SHELL || error "$command"
				set -eou pipefail
				pass_file="\$(printenv | grep ELASTIC_PASSWORD_FILE | cut -f 2- -d '=')"

				if [ -n "\$pass_file" ]; then
					cat "\$pass_file"
				else
					printenv | grep ELASTIC_PASSWORD | cut -f 2- -d '='
				fi
			SHELL
		}

		# Wait to be ready and create roles


			# wget --user "$bootstrap_user" --password "$(bootstrap_password)"  \
			# 	--post-data= '{
			# 		"cluster": ["manage_index_templates", "monitor", "manage_ilm"],
			# 		"indices": [
			# 			{
			# 				"names": [ "fluentd-*" ],
			# 				"privileges": ["write","create","delete","create_index","manage","manage_ilm"]
			# 			}
			# 		]
			# 	}' \
			# 	--header="Content-Type: application/json" \
			# 	"https://elasticsearch:9200/_security/role/fluentd" \
			# 	>&2

		"$pod_script_env_file" exec-nontty toolbox /bin/bash <<-SHELL || error "$command"
			set -eou pipefail

			export CURL_CA_BUNDLE="/etc/ssl/fullchain.pem"

			timeout="${var_custom__elasticsearch_timeout:-150}"
			end=\$((SECONDS+\$timeout))
			success=false

			url='https://elasticsearch:9200/_cluster/health?wait_for_status=yellow'

			while [ \$SECONDS -lt \$end ]; do
				current=\$((end-SECONDS))
				msg="\$timeout seconds - \$current second(s) remaining"
				>&2 echo "wait for elasticsearch to be ready (\$msg)"

				echo wget --ca-certificate="/etc/ssl/fullchain.pem" --user "$bootstrap_user" --password "$(bootstrap_password)" "\$url" >&2

				if wget --ca-certificate="/etc/ssl/fullchain.pem" --user "$bootstrap_user" --password "$(bootstrap_password)" "\$url" >&2; then
					success=true
					echo ''
					echo "> elasticsearch is ready" >&2
					break
				fi

				sleep 5
			done

			if [ "\$success" != 'true' ]; then
				echo "timeout while waiting for elasticsearch" >&2
				exit 2
			fi

			echo "creating the elasticsearch roles..." >&2

			echo curl --fail -sS -u "$bootstrap_user:$(bootstrap_password)" \
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

			curl --fail -sS -u "$bootstrap_user:$(bootstrap_password)" \
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
		SHELL

		# Create Users
		echo "creating the elasticsearch roles..." >&2

		while IFS='=' read -r key value; do
			user="$(echo "$key" | xargs)"

			if [ "$user" != "$bootstrap_user" ] && [[ ! "$user" == \#* ]]; then
				"$pod_script_env_file" exec-nontty toolbox \
					CURL_CA_BUNDLE="/etc/ssl/fullchain.pem" && curl -u "$bootstrap_user:$(bootstrap_password)" \
						-XPOST "https://elasticsearch:9200/_xpack/security/user/${user}/_password" \
						-d"$(echo "$value" | xargs)" \
						-H "Content-Type: application/json"
			fi
		done < "$pod_layer_dir/env/elasticsearch/users.txt"

		# Define Keystore
		if [ "${var_load__custom__s3_snapshot:-}" ]; then
			while IFS='=' read -r key value; do
				echo "$value" | xargs \
					| "$pod_script_env_file" exec-nontty elasticsearch \
						bin/elasticsearch-keystore add --stdin --force "$(echo "$key" | xargs)"
			done < "$pod_layer_dir/env/elasticsearch/keystore.txt"
		fi
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
		fi

		"$pod_script_env_file" "shared:log:file_descriptors:summary" --max_amount="$max_amount"
		"$pod_script_env_file" "shared:log:disk:summary" \
			--verify_size_docker_dir="${var_custom__log_summary__verify_size_docker_dir:-}" \
			--verify_size_containers="${var_custom__log_summary__verify_size_containers:-}"
		;;
	"action:exec:"*)
		action="${command#action:exec:}"

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
			"setup"|\
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