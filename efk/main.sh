#!/bin/bash
# shellcheck disable=SC1090,SC2154
set -eou pipefail

. "${pod_vars_dir}/vars.sh"

pod_env_shared_file="$pod_layer_dir/main/log/scripts/efk.sh"

command="${1:-}"

case "$command" in
  *)
    "$pod_env_shared_file" "$command" "$@"
    ;;
esac