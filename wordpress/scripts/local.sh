#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2153
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_layer_dir="$POD_LAYER_DIR"
pod_full_dir="$POD_FULL_DIR"
pod_script_env_file="$POD_SCRIPT_ENV_FILE"

. "${pod_vars_dir}/vars.sh"

pod_env_shared_file="$pod_layer_dir/main/wordpress/scripts/shared.sh"

pod_layer_base_dir="$(dirname "$pod_layer_dir")"
base_dir="$(dirname "$pod_layer_base_dir")"

CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function error {
	msg="$(date '+%F %T') - ${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${1:-}"
	>&2 echo -e "${RED}${msg}${NC}"
	exit 2
}

if [ -z "$base_dir" ] || [ "$base_dir" = "/" ]; then
	msg="This project must be in a directory structure of type"
	msg="$msg [base_dir]/[pod_layer_base_dir]/[this_repo] with"
	msg="$msg base_dir different than '' or '/' instead of $pod_layer_dir"
	error "$msg"
fi

ctl_layer_dir="$base_dir/ctl"
app_layer_dir="$base_dir/apps/$var_dev_repo_dir_wordpress"

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env)."
fi

shift;

start="$(date '+%F %T')"

case "$command" in
	"prepare"|"setup"|"migrate"|"stop"|"rm"|"clear")
		echo -e "${CYAN}$(date '+%F %T') - env (local) - $command - start${NC}"
		;;
esac

case "$command" in
	"prepare")
		"$pod_env_shared_file" "local:prepare" \
			--env_local_repo="$var_env_local_repo" \
			--ctl_layer_dir="$ctl_layer_dir" --opts "${@}"

		sudo chmod +x "$app_layer_dir/"
		cp "$pod_full_dir/env/wordpress/.env" "$app_layer_dir/.env"
		chmod +r "$app_layer_dir/.env"
		chmod 777 "$app_layer_dir/web/app/uploads/"
		;;
	"setup")
		"$pod_env_shared_file" stop wordpress composer 
		"$pod_env_shared_file" rm wordpress composer 
		"$pod_env_shared_file" stop mysql
		"$pod_env_shared_file" up mysql composer
		"$pod_env_shared_file" exec composer composer install --verbose
		"$pod_env_shared_file" "$command" "$@"
		;;
	"migrate")
		"$pod_env_shared_file" rm wordpress composer 
		"$pod_env_shared_file" stop mysql
		"$pod_env_shared_file" up mysql composer
		# "$pod_env_shared_file" exec composer composer clear-cache
		# "$pod_env_shared_file" exec composer composer update --verbose
		"$pod_env_shared_file" "$command" "$@"
		;;
	"stop"|"rm")
		"$pod_env_shared_file" "$command" "$@"
		"$ctl_layer_dir/run" "$command"
		;;
	"clear-all")
		"$pod_script_env_file" "s3:task:wp_uploads" --s3_cmd=rb
		"$pod_script_env_file" "s3:task:wp_db" --s3_cmd=rb
		"$pod_script_env_file" clear
		;;
	"clear")
		"$pod_script_env_file" rm
		sudo docker volume rm -f "${var_env}-${var_ctx}-${var_pod_name}_mysql"
		sudo rm -rf "${base_dir}/data/${var_env}/${var_ctx}/${var_pod_name}/"
		;;
	*)
		"$pod_env_shared_file" "$command" "$@"
		;;
esac

end="$(date '+%F %T')"

case "$command" in
	"prepare"|"setup"|"migrate"|"stop"|"rm"|"clear")
		echo -e "${CYAN}$(date '+%F %T') - env (local) - $command - end${NC}"
		echo -e "${CYAN}env (local) - $command - $start - $end${NC}"
		;;
esac