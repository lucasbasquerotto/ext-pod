#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC1117,SC2153,SC2214
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_layer_dir="$POD_LAYER_DIR"
pod_script_env_file="$POD_SCRIPT_ENV_FILE"

. "${pod_vars_dir}/vars.sh"

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

while getopts ':-:' OPT; do
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		days_ago ) arg_days_ago="${OPTARG:-}";;
		force ) arg_force="${OPTARG:-}";;
		max_amount ) arg_max_amount="${OPTARG:-}";;
		??* ) ;; ## ignore
		\? )  ;; ## ignore
	esac
done
shift $((OPTIND-1))

pod_main_run_file="$pod_layer_dir/main/scripts/main.sh"
nginx_run_file="$pod_layer_dir/$var_shared__script_dir/services/nginx.sh"
nextcloud_run_file="$pod_layer_dir/$var_shared__script_dir/services/nextcloud.sh"

case "$command" in
	"upgrade")
		if [ "${var_custom__use_main_network:-}" = "true" ]; then
			"$pod_main_run_file" "setup:main:network"
		fi

		"$pod_main_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"backup")
		if [ "${var_custom__use_logrotator:-}" = "true" ]; then
			"$pod_main_run_file" run logrotator
		fi

		"$pod_main_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"local:prepare")
		"$arg_ctl_layer_dir/run" dev-cmd bash "/root/w/r/$arg_env_local_repo/run" ${arg_opts[@]+"${arg_opts[@]}"}
		;;
	"prepare")
		data_dir="/var/main/data"

		"$pod_script_env_file" up "toolbox"

		"$pod_script_env_file" exec-nontty "toolbox" /bin/bash <<-SHELL
			set -eou pipefail

			if [ "${var_custom__use_nginx:-}" = "true" ]; then
				if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "web" ]; then
					dir_nginx="$data_dir/sync/nginx"

					dir="\${dir_nginx}/auto"
					file="\${dir}/ips-blacklist-auto.conf"

					if [ ! -f "\$file" ]; then
						mkdir -p "\$dir"
						cat <<-EOF > "\$file"
							# 127.0.0.1 1;
							# 1.2.3.4/16 1;
						EOF
					fi

					dir="\${dir_nginx}/manual"
					file="\${dir}/ips-blacklist.conf"

					if [ ! -f "\$file" ]; then
						mkdir -p "\$dir"
						cat <<-EOF > "\$file"
							# 127.0.0.1 1;
							# 0.0.0.0/0 1;
						EOF
					fi

					dir="\${dir_nginx}/manual"
					file="\${dir}/ua-blacklist.conf"

					if [ ! -f "\$file" ]; then
						mkdir -p "\$dir"
						cat <<-EOF > "\$file"
							# ~(Mozilla|Chrome) 1;
							# "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36" 1;
							# "python-requests/2.18.4" 1;
						EOF
					fi

					dir="\${dir_nginx}/manual"
					file="\${dir}/allowed-hosts.conf"

					if [ ! -f "\$file" ]; then
						mkdir -p "\$dir"
						cat <<-EOF > "\$file"
							# *.googlebot.com
							# *.google.com
						EOF
					fi
				fi
			fi

			if [ "${var_custom__use_mysql:-}" = "true" ]; then
				if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
					dir="$data_dir/mysql"

					if [ ! -d "\$dir" ]; then
						mkdir -p "\$dir"
						chmod 755 "\$dir"
					fi

					dir="$data_dir/tmp/mysql"

					if [ ! -d "\$dir" ]; then
						mkdir -p "\$dir"
						chmod 777 "\$dir"
					fi

					dir="$data_dir/tmp/log/mysql"

					if [ ! -d "\$dir" ]; then
						mkdir -p "\$dir"
						chmod 777 "\$dir"
					fi
				fi
			fi

			if [ "${var_custom__use_mongo:-}" = "true" ]; then
				if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
					dir="$data_dir/mongo/db"

					if [ ! -d "\$dir" ]; then
						mkdir -p "\$dir"
						chmod 755 "\$dir"
					fi

					dir="$data_dir/mongo/dump"

					if [ ! -d "\$dir" ]; then
						mkdir -p "\$dir"
						chmod 755 "\$dir"
					fi
				fi
			fi
		SHELL
		;;
	"setup")
		if [ "${var_custom__use_mongo:-}" = "true" ]; then
			if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
				"$pod_script_env_file" up mongo

				info "$command - init the mongo database if needed"
				"$pod_script_env_file" run mongo_init /bin/bash <<-SHELL
					set -eou pipefail

					for i in \$(seq 1 30); do
						mongo mongo/"$var_shared__mongo__setup__db_name" \
							--authenticationDatabase admin \
							--username "$var_shared__mongo__setup__user_name" \
							--password "$var_shared__mongo__setup__user_pass" \
							--eval "
								rs.initiate({
									_id: 'rs0',
									members: [ { _id: 0, host: 'localhost:27017' } ]
								})
							" && s=\$? && break || s=\$?;
						echo "Tried \$i times. Waiting 5 secs...";
						sleep 5;
					done;

					if [ "\$s" != "0" ]; then
						exit "\$s"
					fi

					for i in \$(seq 1 30); do
						mongo mongo/admin \
							--authenticationDatabase admin \
							--username "$var_shared__mongo__setup__user_name" \
							--password "$var_shared__mongo__setup__user_pass" \
							/tmp/main/init.js && s=\$? && break || s=\$?;
						echo "Tried \$i times. Waiting 5 secs...";
						sleep 5;
					done;

					if [ "\$s" != "0" ]; then
						exit "\$s"
					fi
				SHELL
			fi
		fi

		"$pod_main_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"migrate")
		if [ "${var_custom__use_certbot:-}" = "true" ]; then
			info "$command - start certbot if needed..."
			"$pod_script_env_file" "main:task:certbot"
		fi

		if [ "${var_custom__use_nextcloud:-}" = "true" ]; then
			info "$command - prepare nextcloud..."
			"$pod_script_env_file" "shared:service:nextcloud:setup"
		fi
		;;
	"shared:service:nextcloud:setup")
		"$pod_script_env_file" "service:nextcloud:setup" \
			--task_name="nextcloud" \
			--subtask_cmd="$command" \
			--admin_user="$var_shared__nextcloud__setup__admin_user" \
			--admin_pass="$var_shared__nextcloud__setup__admin_pass" \
			--nextcloud_url="$var_shared__nextcloud__setup__url" \
			--nextcloud_domain="$var_shared__nextcloud__setup__domain" \
			--nextcloud_host="$var_shared__nextcloud__setup__host" \
			--nextcloud_protocol="$var_shared__nextcloud__setup__protocol"

		"$pod_script_env_file" "service:nextcloud:fs" \
			--task_name="nextcloud_action" \
			--subtask_cmd="$command" \
			--mount_point="/action" \
			--datadir="/var/main/data/action"

		"$pod_script_env_file" "service:nextcloud:fs" \
			--task_name="nextcloud_data" \
			--subtask_cmd="$command" \
			--mount_point="/data" \
			--datadir="/var/main/data"

		"$pod_script_env_file" "service:nextcloud:fs" \
			--task_name="nextcloud_sync" \
			--subtask_cmd="$command" \
			--mount_point="/sync" \
			--datadir="/var/main/data/sync"

		if [ "${var_shared__nextcloud__s3_backup__enable:-}" = "true" ]; then
			"$pod_script_env_file" "service:nextcloud:s3" \
				--task_name="nextcloud_backup" \
				--subtask_cmd="$command" \
				--mount_point="/backup" \
				--bucket="$var_shared__nextcloud__s3_backup__bucket" \
				--hostname="$var_shared__nextcloud__s3_backup__hostname" \
				--port="$var_shared__nextcloud__s3_backup__port" \
				--region="$var_shared__nextcloud__s3_backup__region" \
				--use_ssl="$var_shared__nextcloud__s3_backup__use_ssl" \
				--use_path_style="$var_shared__nextcloud__s3_backup__use_path_style" \
				--legacy_auth="$var_shared__nextcloud__s3_backup__legacy_auth"  \
				--key="$var_shared__nextcloud__s3_backup__access_key" \
				--secret="$var_shared__nextcloud__s3_backup__secret_key"
		fi

		if [ "${var_shared__nextcloud__s3_uploads__enable:-}" = "true" ]; then
			"$pod_script_env_file" "service:nextcloud:s3" \
				--task_name="nextcloud_uploads" \
				--subtask_cmd="$command" \
				--mount_point="/uploads" \
				--bucket="$var_shared__nextcloud__s3_uploads__bucket" \
				--hostname="$var_shared__nextcloud__s3_uploads__hostname" \
				--port="$var_shared__nextcloud__s3_uploads__port" \
				--region="$var_shared__nextcloud__s3_uploads__region" \
				--use_ssl="$var_shared__nextcloud__s3_uploads__use_ssl" \
				--use_path_style="$var_shared__nextcloud__s3_uploads__use_path_style" \
				--legacy_auth="$var_shared__nextcloud__s3_uploads__legacy_auth"  \
				--key="$var_shared__nextcloud__s3_uploads__access_key" \
				--secret="$var_shared__nextcloud__s3_uploads__secret_key"
		fi
		;;
	"action:exec:block_ips")
		"$pod_script_env_file" "shared:nginx:log:verify"

		dest_last_day_file="$("$pod_script_env_file" "shared:log:nginx:day" \
			--force="${arg_force:-}" \
			--days_ago="1")"

		dest_day_file=""

		if [ "${var_shared__block_ips__action_exec__current_day:-}" = "true" ]; then
			dest_day_file="$("$pod_script_env_file" "shared:log:nginx:day" --force="${arg_force:-}")"
		fi

		nginx_sync_base_dir="/var/main/data/sync/nginx"
		log_hour_path_prefix="$("$pod_script_env_file" "shared:log:nginx:hour_path_prefix")"

		"$pod_script_env_file" "service:nginx:block_ips" \
			--task_name="block_ips" \
			--subtask_cmd="$command" \
			--max_amount="${var_shared__block_ips__action_exec__max_amount:-$arg_max_amount}" \
			--output_file="$nginx_sync_base_dir/auto/ips-blacklist-auto.conf" \
			--manual_file="$nginx_sync_base_dir/manual/ips-blacklist.conf" \
			--allowed_hosts_file="$nginx_sync_base_dir/manual/allowed-hosts.conf" \
			--log_file_last_day="$dest_last_day_file" \
			--log_file_day="$dest_day_file" \
			--amount_day="$var_shared__block_ips__action_exec__amount_day" \
			--log_file_hour="$log_hour_path_prefix.$(date -u '+%Y-%m-%d.%H').log" \
			--log_file_last_hour="$log_hour_path_prefix.$(date -u -d '1 hour ago' '+%Y-%m-%d.%H').log" \
			--amount_hour="$var_shared__block_ips__action_exec__amount_hour"
		;;
	"shared:log:nginx:summary")
		"$pod_script_env_file" "shared:nginx:log:verify"

		dest_day_file="$("$pod_script_env_file" "shared:log:nginx:day" \
			--force="${arg_force:-}" \
			--days_ago="${arg_days_ago:-}")"

		"$pod_script_env_file" "service:nginx:log:summary:total" \
			--task_name="nginx_log" \
			--subtask_cmd="$command" \
			--log_file="$dest_day_file" \
			--log_idx_ip="1" \
			--log_idx_user="2" \
			--log_idx_duration="3" \
			--log_idx_status="4" \
			--log_idx_http_user="5" \
			--log_idx_time="6" \
			--max_amount="${var_shared__block_ips__action_exec__max_amount:-$arg_max_amount}" \
		;;
	"shared:log:nginx:day")
		"$pod_script_env_file" "shared:nginx:log:verify"

		log_hour_path_prefix="$("$pod_script_env_file" "shared:log:nginx:hour_path_prefix")"
		dest_base_path="/var/log/main/nginx"

		"$pod_script_env_file" exec-nontty toolbox /bin/bash <<-SHELL
			set -eou pipefail

			[ -n "${arg_days_ago:-}" ] && date_arg="${arg_days_ago:-} day ago" || date_arg="today"
			date="\$(date -u -d "\$date_arg" '+%Y-%m-%d')"
			log_day_src_path_prefix="$log_hour_path_prefix.\$date"
			dest_day_file="${dest_base_path}/nginx.\$date.log"

			>&2 mkdir -p "$dest_base_path"

			if [ -f "\$dest_day_file" ]; then
				if [ ! "${arg_force:-}" = "true" ]; then
					echo "\$dest_day_file"
					exit 0
				fi

				>&2 rm -f "\$dest_day_file"
			fi

			for i in \$(seq -f "%02g" 1 24); do
				log_day_src_path_aux="\$log_day_src_path_prefix.\$i.log"

				if [ -f "\$log_day_src_path_aux" ]; then
					cat "\$log_day_src_path_aux" >> "\$dest_day_file"
				fi
			done

			if [ ! -f "\$dest_day_file" ]; then
				>&2 touch "\$dest_day_file"
			fi

			echo "\$dest_day_file"
		SHELL
		;;
	"shared:nginx:log:verify")
		case "$var_custom__pod_type" in
			"app"|"web")
				;;
			*)
				error "$command: pod_type ($var_custom__pod_type) not supported"
				;;
		esac

		if [ "${var_custom__use_fluentd:-}" != "true" ]; then
				error "$command: fluentd must be used"
		fi
		;;
	"shared:log:nginx:hour_path_prefix")
		log_hour_path_prefix="/var/log/main/fluentd/main/docker.nginx/docker.nginx.stdout"
		echo "$log_hour_path_prefix"
		;;
	"action:exec:nginx_reload")
		"$pod_script_env_file" "service:nginx:reload" ${args[@]+"${args[@]}"}
		;;
	"action:subtask:"*)
		task_name="${command#action:subtask:}"

		opts=()

		opts+=( "--task_name=$task_name" )
		opts+=( "--subtask_cmd=$command" )

		opts+=( "--toolbox_service=toolbox" )
		opts+=( "--action_dir=/var/main/data/action" )

		"$pod_main_run_file" "action:subtask" "${opts[@]}"
		;;
	"service:nginx:"*)
		"$nginx_run_file" "$command" \
			--toolbox_service="toolbox" \
			--nginx_service="nginx" \
			${args[@]+"${args[@]}"}
		;;
	"service:nextcloud:"*)
		"$nextcloud_run_file" "$command" \
			--toolbox_service="toolbox" \
			--nextcloud_service="nextcloud" \
			${args[@]+"${args[@]}"}
		;;
	*)
		"$pod_main_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
esac
