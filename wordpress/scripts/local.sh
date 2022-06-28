#!/bin/bash
set -eou pipefail

# shellcheck disable=SC2154
pod_layer_dir="$var_pod_layer_dir"
# shellcheck disable=SC2154
pod_script_env_file="$var_pod_script"
# shellcheck disable=SC2154
pod_env_shared_file="$var_run__general__script_dir/shared.sh"
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

case "$command" in
	"upgrade")
		"$pod_env_shared_file" "$command" "$@"
		info "login and access the admin dashboard at: /wp/wp-login.php"
		;;
	"c")
		"$pod_env_shared_file" exec composer composer update --verbose
		;;
	"composer")
		"$pod_env_shared_file" exec composer composer clear-cache
		"$pod_env_shared_file" exec composer composer update --verbose
		;;
	"prepare")
		# shellcheck disable=SC2154
		pod_type="$var_main__pod_type"

		if [ "${var_custom__app_dev:-}" = "true" ]; then
			if [ -z "${var_dev__repo_dir_wordpress:-}" ]; then
				error "[error] wordpress directory not defined (var_dev__repo_dir_wordpress)"
			fi

			app_dir="$pod_layer_dir/$var_dev__repo_dir_wordpress"

			info "preparing wordpress development environment (app)..."
			sudo chmod +x "$app_dir/"
			cp "$pod_layer_dir/env/wordpress/.env" "$app_dir/.env"
			chmod +r "$app_dir/.env"
			chmod 777 "$app_dir/web/app/uploads/"
		fi

		"$pod_script_env_file" up wordpress

		if [ "${var_custom__app_dev:-}" = "true" ]; then
			if [ "$pod_type" = "app" ] || [ "$pod_type" = "web" ]; then
				"$pod_script_env_file" exec-nontty wordpress \
					bash "$inner_run_file" "inner:custom:local:prepare"
			fi
		fi

		"$pod_env_shared_file" "$command" "$@"
		;;
	"inner:custom:local:prepare")
		dir="/var/www/html/web"

		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		chmod 777 "$dir"

		dir="/var/www/html/web/app"

		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		chmod 777 "$dir"

		dir="/var/www/html/web/app/plugins"

		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		chmod -R 777 "$dir"
		;;
	"setup:new")
		if [ "${var_custom__app_dev:-}" = "true" ] && [ "${var_main__use_composer:-}" = "true" ]; then
			"$pod_env_shared_file" up mysql composer
			"$pod_env_shared_file" exec composer composer install --verbose
		fi

		"$pod_env_shared_file" "$command" "$@"
		;;
	"migrate")
		"$pod_env_shared_file" "$command" "$@"

		if [ "${var_custom__app_dev:-}" = "true" ]; then
			"$pod_env_shared_file" exec-nontty wordpress chown -R 33 /var/www/html/web/wp/
		fi
		;;
	"clear")
		"$pod_script_env_file" "local:clear"
		;;
	"clear-all")
		"$pod_script_env_file" "local:clear-all"
		;;
	"clear-remote")
		if [ "${var_main__use_s3:-}" = 'true' ]; then
			"$pod_script_env_file" "s3:subtask:s3_uploads" --s3_cmd=rb
			"$pod_script_env_file" "s3:subtask:s3_backup" --s3_cmd=rb

			if [ "${var_run__enable__uploads_replica:-}" = 'true' ]; then
				"$pod_script_env_file" "s3:subtask:s3_uploads_replica" --s3_cmd=rb
			fi

			if [ "${var_run__enable__backup_replica:-}" = 'true' ]; then
				"$pod_script_env_file" "s3:subtask:s3_backup_replica" --s3_cmd=rb
			fi
		fi
		;;
	*)
		"$pod_env_shared_file" "$command" "$@"
		;;
esac
