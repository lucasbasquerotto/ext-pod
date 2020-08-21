#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

# shellcheck disable=SC2153
pod_vars_dir="$POD_VARS_DIR"
# shellcheck disable=SC2153
pod_layer_dir="$POD_LAYER_DIR"
# shellcheck disable=SC2153
pod_script_env_file="$POD_SCRIPT_ENV_FILE"
# shellcheck disable=SC2153
pod_data_dir="$POD_DATA_DIR"

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
mysql_run_file="$pod_layer_dir/$var_shared__script_dir/services/mysql.sh"
redis_run_file="$pod_layer_dir/$var_shared__script_dir/services/redis.sh"
log_run_file="$pod_layer_dir/$var_shared__script_dir/log.sh"
test_run_file="$pod_layer_dir/$var_shared__script_dir/test.sh"

case "$command" in
	"upgrade")
		if [ "${var_custom__use_main_network:-}" = "true" ]; then
			"$pod_main_run_file" "setup:main:network"
		fi

		"$pod_main_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"backup"|"local.backup")
		"$pod_script_env_file" "shared:bg:$command"
		;;
	"action:exec:backup"|"action:exec:local.backup")
		task_name="${command#action:exec:}"

		if [ "${var_custom__use_logrotator:-}" = "true" ]; then
			"$pod_script_env_file" "shared:unique:rotate" ||:
		fi

		"$pod_main_run_file" "$task_name"
		;;
	"action:exec:rotate")
		"$pod_script_env_file" run logrotator
		;;
	"local:prepare")
		"$arg_ctl_layer_dir/run" dev-cmd bash "/root/w/r/$arg_env_local_repo/run" ${arg_opts[@]+"${arg_opts[@]}"}
		;;
	"prepare")
		data_dir="/var/main/data"

		"$pod_script_env_file" up "toolbox"

		"$pod_script_env_file" exec-nontty "toolbox" /bin/bash <<-SHELL || error "$command"
			set -eou pipefail

			dir="$data_dir/log/bg"

			if [ ! -d "\$dir" ]; then
				mkdir -p "\$dir"
				chmod 777 "\$dir"
			fi

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

					dir="\${dir_nginx}/manual"
					file="\${dir}/log-exclude-paths.conf"

					if [ ! -f "\$file" ]; then
						mkdir -p "\$dir"
						cat <<-EOF > "\$file"
							# theia.localhost
							# /app/uploads/
						EOF
					fi

					dir="\${dir_nginx}/manual"
					file="\${dir}/log-exclude-paths-full.conf"

					if [ ! -f "\$file" ]; then
						mkdir -p "\$dir"
						cat <<-EOF > "\$file"
							# theia.localhost
							# /app/uploads/
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
		"$pod_script_env_file" "shared:bg:setup"
		;;
	"action:exec:setup")
		if [ "${var_custom__use_mongo:-}" = "true" ]; then
			if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
				"$pod_script_env_file" up mongo

				info "$command - init the mongo database if needed"
				"$pod_script_env_file" run mongo_init /bin/bash <<-SHELL || error "$command"
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

		"$pod_main_run_file" setup
		;;
	"migrate")
		if [ "$var_custom__use_varnish" = "true" ]; then
			"$pod_script_env_file" up varnish

			info "$command - clear varnish cache..."
			"$pod_script_env_file" "service:varnish:clear"
		fi

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
		"$pod_script_env_file" "shared:log:nginx:verify"

		dest_last_day_file="$("$pod_script_env_file" "shared:log:nginx:day" \
			--force="${arg_force:-}" \
			--days_ago="1" \
			--max_amount="${arg_max_amount:-}")"

		dest_day_file=""

		if [ "${var_shared__block_ips__action_exec__current_day:-}" = "true" ]; then
			dest_day_file="$("$pod_script_env_file" "shared:log:nginx:day" \
				--force="${arg_force:-}" \
				--max_amount="${arg_max_amount:-}")"
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
	"action:exec:nginx_reload")
		"$pod_script_env_file" "service:nginx:reload" ${args[@]+"${args[@]}"}
		;;
	"shared:bg:"*)
		task_name="${command#shared:bg:}"

		"$pod_script_env_file" "bg:subtask" \
			--task_name="$task_name" \
			--subtask_cmd="$command" \
			--bg_file="$pod_data_dir/log/bg/$task_name.$(date -u '+%Y%m%d.%H%M%S').$$.log" \
			--action_dir="/var/main/data/action"
		;;
	"shared:unique:"*)
		task_name="${command#shared:unique:}"

		opts=()

		opts+=( "--task_name=$task_name" )
		opts+=( "--subtask_cmd=$command" )

		opts+=( "--toolbox_service=toolbox" )
		opts+=( "--action_dir=/var/main/data/action" )

		"$pod_main_run_file" "unique:subtask" "${opts[@]}"
		;;
	"action:exec:watch")
		inotifywait -m "$pod_data_dir/action" -e create -e moved_to |
			while read -r _ _ file; do
				"$pod_script_env_file" "shared:action:$file"
			done
		;;
	"shared:action:"*)
		task_name="${command#shared:action:}"

		opts=()

		opts+=( "--task_name=$task_name" )
		opts+=( "--subtask_cmd=$command" )

		opts+=( "--toolbox_service=toolbox" )
		opts+=( "--action_dir=/var/main/data/action" )

		"$pod_main_run_file" "action:subtask" "${opts[@]}"
		;;
	"action:exec:log_register."*)
		task_name="${command#action:exec:log_register.}"
		"$pod_script_env_file" "shared:log:register:$task_name"
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
	"service:mysql:"*)
		"$mysql_run_file" "$command" \
			--toolbox_service="toolbox" \
			${args[@]+"${args[@]}"}
		;;
	"service:redis:"*)
		"$redis_run_file" "$command" \
			--toolbox_service="toolbox" \
			--redis_service="redis" \
			${args[@]+"${args[@]}"}
		;;
	"service:varnish:clear")
		"$pod_script_env_file" exec-nontty varnish varnishadm ban req.url '~' '.'
		;;
	"delete:old")
		info "$command - clear old files"
		>&2 "$pod_script_env_file" up toolbox

		dirs=( "/var/log/main/" "/tmp/main/tmp/" )

		re_number='^[0-9]+$'
		delete_old_days="${var_shared__delete_old__days:-7}"

		if ! [[ $delete_old_days =~ $re_number ]] ; then
			msg="The variable 'var_shared__delete_old__days' should be a number"
			error "$command: $msg (value=$delete_old_days)"
		fi

		info "$command - create the backup base directory and clear old files"
		"$pod_script_env_file" exec-nontty toolbox /bin/bash <<-SHELL || error "$command"
			set -eou pipefail

			for dir in "${dirs[@]}"; do
				if [ -d "\$dir" ]; then
					# remove old files and directories
					find "\$dir" -mindepth 1 -ctime +$delete_old_days -delete -print;

					# remove old and empty directories
					find "\$dir" -mindepth 1 -type d -ctime +$delete_old_days -empty -delete -print;
				fi
			done
		SHELL
		;;
	"shared:log:"*)
		"$log_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	"shared:test:"*)
		"$test_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
	*)
		"$pod_main_run_file" "$command" ${args[@]+"${args[@]}"}
		;;
esac
