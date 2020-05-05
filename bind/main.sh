#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2153
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_layer_dir="$POD_LAYER_DIR"
pod_script_env_file="$POD_SCRIPT_ENV_FILE"

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
  "new-key")
		"$pod_script_env_file" run dnssec bash <<-SHELL
			set -eou pipefail

			>&2 rm -rf /tmp/main/bind/keys
			>&2 mkdir -p /tmp/main/bind/keys

			cd /tmp/main/bind/keys
			>&2 dnssec-keygen -C -a HMAC-MD5 -b 512 -n USER "$var_bind_zone".
			>&2 file_name="\$(ls -rt | grep "$var_bind_zone" | tail -n1)"
			>&2 new_key="\$(cat "\$file_name" | awk '{ print \$7 }')"
			echo "\$new_key"
		SHELL
		;;
	"print-new-key")
		new_key="$("$pod_script_env_file" "new-key")"
		echo "new_key=$new_key"
		;;
	"bind:"*)
		ctx="${command#bind:}"
		prefix="var_bind_${ctx}"
		zone_name="${prefix}_zone_name"

		"$pod_script_env_file" exec-nontty toolbox <<-SHELL
			rm -rf /tmp/main/bind/keys
			mkdir /tmp/main/bind/keys
		SHELL

		"$pod_script_env_file" run dnssec <<-SHELL
		  cd /tmp/main/bind/keys
			dnssec-keygen -a NSEC3RSASHA1 -b 2048 -n ZONE "$zone_name"
			dnssec-keygen -f KSK -a NSEC3RSASHA1 -b 4096 -n ZONE "$zone_name"

			for key in \$(ls K"$zone_name"*.key)
			do
				echo "\\\$INCLUDE \$key" >> "$zone_name".zone
			done

			salt="\$(head -c 1000 /dev/random | sha1sum | cut -b 1-16)"
			dnssec-signzone -3 "\$salt" -A -N INCREMENT -o "$zone_name" -t "$zone_name".zone
		SHELL
		;;
	*)
		"$pod_env_shared_file" "$command" "$@"
		;;
esac