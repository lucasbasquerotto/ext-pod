#!/bin/bash
# shellcheck disable=SC2154
set -eou pipefail

pod_script_env_file="$var_pod_script"

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
}

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env)."
fi

shift;

pod_env_shared_file="$var_run__general__script_dir/shared.sh"

case "$command" in
	*)
		"$pod_env_shared_file" "$command" "$@"
		;;
esac