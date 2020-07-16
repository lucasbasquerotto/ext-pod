#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2153
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
	error "No command entered (env)."
fi

shift;

pod_env_run_file="$pod_layer_dir/main/scripts/main.sh"

case "$command" in
	"upgrade")
		"$pod_env_run_file" "setup:main:network"
		"$pod_env_run_file" "$command" "$@"
		;;
	"setup")
		data_dir="/var/main/data"

		"$pod_script_env_file" up "$var_run__general__toolbox_service"

		"$pod_script_env_file" exec-nontty "$var_run__general__toolbox_service" /bin/bash <<-SHELL
			if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
				dir="$data_dir/mysql"

				if [ ! -d "\$dir" ]; then
					mkdir -p "\$dir"
					chmod 755 "\$dir"
				fi
			fi

			if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "web" ]; then
				dir="$data_dir/mediawiki/uploads"

				if [ ! -d "\$dir" ]; then
					mkdir -p "\$dir"
					chmod 777 "\$dir"
				fi

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
		SHELL

		"$pod_env_run_file" "$command" "$@"
		;;
	"migrate")
		if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "db" ]; then
			"$pod_env_run_file" up mysql
		fi

		if [ "$var_custom__pod_type" = "app" ] || [ "$var_custom__pod_type" = "web" ]; then
			"$pod_env_run_file" up mediawiki

			info "$command - verify the need to setup the mediawiki database"
			count="$("$pod_script_env_file" "migrate:db:table:count")"

			if [ "$count" = "0" ]; then
				info "$command - setup the mediawiki database..."
				"$pod_env_run_file" exec-nontty mediawiki php maintenance/upgrade.php
			else
				>&2 echo "skipping..."
			fi
		fi

		if [ "${var_custom__use_certbot:-}" = "true" ]; then
			info "$command - start certbot if needed..."
			"$pod_script_env_file" "main:task:certbot"
		fi

		if [ "${var_custom__use_nextcloud:-}" = "true" ]; then
			info "$command - prepare nextcloud..."
			"$pod_script_env_file" "migrate:custom:nextcloud"
		fi
		;;
	"migrate:db:table:count")
		db_service="mysql"
		db_cmd=""
		db_host="mysql"
		db_port="3306"
		db_remote=""

		if [ "$var_custom__pod_type" != "app" ]; then
			db_service="mysql_cli"
			db_cmd="run"
			db_port="$var_run__migrate__db_port"
			db_remote="true"
		fi

		"$pod_env_run_file" "run:db:main:tables:count:mysql" \
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
	"migrate:custom:nextcloud")
		"$nextcloud_run_file" "nextcloud:setup" \
			--task_name="nextcloud" \
			--subtask_cmd="$command" \
			--toolbox_service="$var_run__general__toolbox_service" \
			--nextcloud_service="nextcloud" \
			--admin_user="$var_custom__nextcloud_admin_user" \
			--admin_pass="$var_custom__nextcloud_admin_pass" \
			--nextcloud_url="$var_custom__nextcloud_url" \
			--nextcloud_domain="$var_custom__nextcloud_domain" \
			--nextcloud_host="$var_custom__nextcloud_host" \
			--nextcloud_protocol="$var_custom__nextcloud_protocol"

		"$nextcloud_run_file" "nextcloud:fs" \
			--task_name="nextcloud_action" \
			--subtask_cmd="$command" \
			--toolbox_service="$var_run__general__toolbox_service" \
			--nextcloud_service="nextcloud" \
			--mount_point="/action" \
			--datadir="/var/main/data/action"

		"$nextcloud_run_file" "nextcloud:fs" \
			--task_name="nextcloud_data" \
			--subtask_cmd="$command" \
			--toolbox_service="$var_run__general__toolbox_service" \
			--nextcloud_service="nextcloud" \
			--mount_point="/data" \
			--datadir="/var/main/data"

		"$nextcloud_run_file" "nextcloud:fs" \
			--task_name="nextcloud_sync" \
			--subtask_cmd="$command" \
			--toolbox_service="$var_run__general__toolbox_service" \
			--nextcloud_service="nextcloud" \
			--mount_point="/sync" \
			--datadir="/var/main/data/sync"

		"$nextcloud_run_file" "nextcloud:s3" \
			--task_name="nextcloud_backup" \
			--subtask_cmd="$command" \
			--toolbox_service="$var_run__general__toolbox_service" \
			--nextcloud_service="nextcloud" \
			--mount_point="/backup" \
			--bucket="$var_custom__s3_backup_bucket" \
			--hostname="$var_custom__s3_backup_hostname" \
			--port="$var_custom__s3_backup_port" \
			--region="$var_custom__s3_backup_region" \
			--use_ssl="$var_custom__s3_backup_use_ssl" \
			--use_path_style="$var_custom__s3_backup_use_path_style" \
			--legacy_auth="$var_custom__s3_backup_legacy_auth"  \
			--key="$var_custom__s3_backup_access_key" \
			--secret="$var_custom__s3_backup_secret_key"

		"$nextcloud_run_file" "nextcloud:s3" \
			--task_name="nextcloud_uploads" \
			--subtask_cmd="$command" \
			--toolbox_service="$var_run__general__toolbox_service" \
			--nextcloud_service="nextcloud" \
			--mount_point="/uploads" \
			--bucket="$var_custom__s3_uploads_bucket" \
			--hostname="$var_custom__s3_uploads_hostname" \
			--port="$var_custom__s3_uploads_port" \
			--region="$var_custom__s3_uploads_region" \
			--use_ssl="$var_custom__s3_uploads_use_ssl" \
			--use_path_style="$var_custom__s3_uploads_use_path_style" \
			--legacy_auth="$var_custom__s3_uploads_legacy_auth"  \
			--key="$var_custom__s3_uploads_access_key" \
			--secret="$var_custom__s3_uploads_secret_key"
		;;
	"actions")
		"$pod_script_env_file" "action:subtask:block_ips"
		"$pod_script_env_file" "action:subtask:nginx_reload"
		;;
	"action:subtask:"*)
		task_name="${command#action:subtask:}"

		opts=()

		opts+=( "--task_name=$task_name" )
		opts+=( "--subtask_cmd=$command" )

		opts+=( "--toolbox_service=$var_run__general__toolbox_service" )
		opts+=( "--action_dir=/var/main/data/action" )

		"$pod_env_run_file" "action:subtask" "${opts[@]}"
		;;
	"action:exec:nginx_reload")
		"$pod_env_run_file" exec-nontty nginx nginx -s reload
		;;
	"action:exec:block_ips")
		case "$var_custom__pod_type" in
			"app"|"web")
				;;
			*)
				error "$command: pod_type ($var_custom__pod_type) not supported"
				;;
		esac

		if [ "$var_custom__use_fluentd" != "true" ]; then
				error "$command: fluentd must be used"
		fi

		log_hour_path_prefix="/var/log/main/fluentd/main/docker.nginx/docker.nginx.stdout"
		tmp_base_path="/tmp/main/run/block_ips"
		tmp_last_day_file="${tmp_base_path}/last_day.log"
		tmp_day_file="${tmp_base_path}/day.log"

		"$pod_script_env_file" exec-nontty "$var_run__general__toolbox_service" /bin/bash <<-SHELL
			set -eou pipefail

			log_last_day_src_path_prefix="$log_hour_path_prefix.$(date -u -d '1 day ago' '+%Y-%m-%d')"
			log_day_src_path_prefix="$log_hour_path_prefix.$(date -u '+%Y-%m-%d')"

			mkdir -p "$tmp_base_path"

			echo "" > "$tmp_last_day_file"
			echo "" > "$tmp_day_file"

			for i in \$(seq -f "%02g" 1 24); do
				log_last_day_src_path_aux="\$log_last_day_src_path_prefix.\$i.log"
				log_day_src_path_aux="\$log_day_src_path_prefix.\$i.log"

				if [ -f "\$log_last_day_src_path_aux" ]; then
					cat "\$log_last_day_src_path_aux" >> "$tmp_last_day_file"
				fi

				if [ -f "\$log_day_src_path_aux" ]; then
					cat "\$log_day_src_path_aux" >> "$tmp_day_file"
				fi
			done
		SHELL

		nginx_sync_base_dir="/var/main/data/sync/nginx"

		"$pod_env_run_file" "run:nginx:block_ips" \
			--task_name="block_ips" \
			--subtask_cmd="$command" \
			--toolbox_service="$var_run__general__toolbox_service" \
			--nginx_service="nginx" \
			--max_ips="$var_task__block_ips__action_exec__max_ips" \
			--output_file="$nginx_sync_base_dir/auto/ips-blacklist-auto.conf" \
			--manual_file="$nginx_sync_base_dir/manual/ips-blacklist.conf" \
			--allowed_hosts_file="$nginx_sync_base_dir/manual/allowed-hosts.conf" \
			--log_file_last_day="$tmp_last_day_file" \
			--log_file_day="$tmp_day_file" \
			--amount_day="$var_task__block_ips__action_exec__amount_day" \
			--log_file_hour="$log_hour_path_prefix.$(date -u '+%Y-%m-%d.%H').log" \
			--log_file_last_hour="$log_hour_path_prefix.$(date -u -d '1 hour ago' '+%Y-%m-%d.%H').log" \
			--amount_hour="$var_task__block_ips__action_exec__amount_hour"
		;;
	*)
		"$pod_env_run_file" "$command" "$@"
		;;
esac