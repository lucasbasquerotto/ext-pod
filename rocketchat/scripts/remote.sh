#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

# shellcheck disable=SC2153
pod_vars_dir="$POD_VARS_DIR"
# shellcheck disable=SC2153
pod_layer_dir="$POD_LAYER_DIR"

# shellcheck disable=SC1090
. "${pod_vars_dir}/vars.sh"


function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
}

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env)."
fi

shift;

pod_env_shared_file="$pod_layer_dir/$var_run__general__script_dir/shared.sh"

case "$command" in
	*)
		"$pod_env_shared_file" "$command" "$@"
		;;
esac