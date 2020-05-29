#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2153
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_layer_dir="$POD_LAYER_DIR"

. "${pod_vars_dir}/vars.sh"

pod_layer_base_dir="$(dirname "$pod_layer_dir")"
base_dir="$(dirname "$pod_layer_base_dir")"

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
	"clear-all")
    mapfile -t list < <(sudo docker ps -aq)
    [[ ${#list[@]} -gt 0 ]] && sudo docker container rm -f "${list[@]}"
		sudo docker container prune -f
		sudo docker network prune -f
		sudo docker volume prune -f
		sudo rm -rf "${base_dir}/data/${var_env}/${var_ctx}/${var_pod_name}/"
		;;
	"migrate")
		if [ "$var_pod_type" = "app" ] || [ "$var_pod_type" = "db" ]; then
			"$pod_env_run_file" up mysql

			info "$command - init the mediawiki database if needed"
			"$pod_script_env_file" "db:connect:mysql"
				--db_service="$var_migrate_db_service" \
				--db_name="$var_migrate_db_name" \
				--db_user="$var_migrate_db_user" \
				--db_pass="$var_migrate_db_pass" \
				--db_connect_wait_secs="$var_migrate_db_connect_wait_secs" \
				--connection_sleep="${var_migrate_connection_sleep:-}"
		fi

		if [ "$var_pod_type" = "app" ] || [ "$var_pod_type" = "web" ]; then
			"$pod_env_run_file" up mediawiki

			info "$command - init the mediawiki database if needed"
			"$pod_env_run_file" exec-nontty mediawiki php maintenance/upgrade.php
		fi
		;;
	*)
		"$pod_env_run_file" "$command" "$@"
		;;
esac