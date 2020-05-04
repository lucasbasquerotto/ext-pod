#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2153
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_layer_dir="$POD_LAYER_DIR"

. "${pod_vars_dir}/vars.sh"

RED='\033[0;31m'
NC='\033[0m' # No Color

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

pod_env_shared_file="$pod_layer_dir/main/scripts/main.sh"

case "$command" in
  "bootstrap:remote:"*)
    ;;
  "restore")
		"$pod_env_shared_file" exec-nontty "$var_restore_container_name" sh -x <<-SHELL
		  cd /var/www/discourse
			discourse enable_restore
			discourse restore $var_restore_filename
			discourse disable_restore
		SHELL
    ;;
  *)
    "$pod_env_shared_file" "$command" "$@"
    ;;
esac