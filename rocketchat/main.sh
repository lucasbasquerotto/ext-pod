#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2153
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_layer_dir="$POD_LAYER_DIR"

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
	"migrate")
		"$pod_env_run_file" up rocketchat mongo

		info "$command - init the mongo database"
		"$pod_env_run_file" run mongo_init

		info "$command - create the hubot user"
		>&2 "$pod_env_run_file" exec-nontty "$var_general_toolbox_service" /bin/bash <<-SHELL
			set -eou pipefail

			curl -H "X-Auth-Token: $var_hubot_auth_token" \
				-H "X-User-Id: $var_hubot_auth_token" \
				-H "Content-type:application/json" \
				$var_hubot_base_url/api/v1/users.create \
				-d "{\
					'email': '$var_hubot_email', \
					'username': '$var_hubot_user',\
					'password': '$var_hubot_password', \
					'name': '$var_hubot_bot_name', \
					'roles': ['bot'], \
					'verified': true, \
					'joinDefaultChannels': false, \
					'requirePasswordChange': false, \
					'sendWelcomeEmail': false \
				}"
		SHELL
		;;
	*)
		"$pod_env_run_file" "$command" "$@"
		;;
esac