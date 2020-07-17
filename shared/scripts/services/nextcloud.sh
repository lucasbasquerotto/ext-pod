#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC1117,SC2153,SC2214
set -eou pipefail

pod_script_env_file="$POD_SCRIPT_ENV_FILE"

GRAY="\033[0;90m"
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
	error "No command entered."
fi

shift;

while getopts ':-:' OPT; do
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		task_name ) arg_task_name="${OPTARG:-}";;
		subtask_cmd ) arg_subtask_cmd="${OPTARG:-}";;
		toolbox_service ) arg_toolbox_service="${OPTARG:-}";;
		nextcloud_service ) arg_nextcloud_service="${OPTARG:-}";;
		connect_wait_secs ) arg_connect_wait_secs="${OPTARG:-}";;
		connection_sleep ) arg_connection_sleep="${OPTARG:-}";;

		admin_user ) arg_admin_user="${OPTARG:-}";;
		admin_pass ) arg_admin_pass="${OPTARG:-}";;
		nextcloud_url ) arg_nextcloud_url="${OPTARG:-}";;
		nextcloud_domain ) arg_nextcloud_domain="${OPTARG:-}";;
		nextcloud_host ) arg_nextcloud_host="${OPTARG:-}";;
		nextcloud_protocol ) arg_nextcloud_protocol="${OPTARG:-}";;

		mount_point ) arg_mount_point="${OPTARG:-}";;

		datadir ) arg_datadir="${OPTARG:-}";;

		bucket ) arg_bucket="${OPTARG:-}";;
		hostname ) arg_hostname="${OPTARG:-}";;
		port ) arg_port="${OPTARG:-}";;
		region ) arg_region="${OPTARG:-}";;
		use_ssl ) arg_use_ssl="${OPTARG:-}";;
		use_path_style ) arg_use_path_style="${OPTARG:-}";;
		legacy_auth ) arg_legacy_auth="${OPTARG:-}";;
		key ) arg_key="${OPTARG:-}";;
		secret ) arg_secret="${OPTARG:-}";;
		??* ) error "$command: Illegal option --$OPT" ;;  # bad long option
		\? )  exit 2 ;;  # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1))

title="$command"
[ -n "${arg_task_name:-}" ] && title="$title - $arg_task_name"
[ -n "${arg_subtask_cmd:-}" ] && title="$title ($arg_subtask_cmd)"

case "$command" in
	"service:nextcloud:setup")
		"$pod_script_env_file" up "$arg_nextcloud_service"
		connect_wait_secs="${arg_connect_wait_secs:-300}"

		need_install="$(
			"$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" /bin/bash <<-SHELL
				set -eou pipefail

				function info {
					msg="\$(date '+%F %T') - \${1:-}"
					>&2 echo -e "${GRAY}$command: \${msg}${NC}"
				}

				function error {
					msg="\$(date '+%F %T') \${1:-}"
					>&2 echo -e "${RED}$command: \${msg}${NC}"
					exit 2
				}

				end=\$((SECONDS+$connect_wait_secs))
				result="continue"

				while [ -n "\${result:-}" ] && [ \$SECONDS -lt \$end ]; do
					current=\$((end-SECONDS))
					msg="$connect_wait_secs seconds - \$current second(s) remaining"

					info "$title - wait for the installation to be ready (\$msg)"
					result="\$(php occ list > /dev/null 2>&1 || echo "continue")"

					if [ -n "\${result:-}" ]; then
						sleep "${arg_connection_sleep:-5}"
					fi
				done

				php occ list | grep '^ *maintenance:install ' | wc -l || :
			SHELL
		)" || error "service:nextcloud:setup"

		if [[ ${need_install:-0} -ne 0 ]]; then
			info "$title: installing nextcloud..."
			"$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" php occ maintenance:install \
				--admin-user="$arg_admin_user" \
				--admin-pass="$arg_admin_pass"
		else
			info "$title: nextcloud already installed"
		fi

		info "$title: define domain and protocol ($arg_nextcloud_domain)"
		"$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" /bin/bash <<-SHELL
			set -eou pipefail

			function info {
				msg="\$(date '+%F %T') - \${1:-}"
				>&2 echo -e "${GRAY}$command: \${msg}${NC}"
			}

			php occ config:system:set trusted_domains 1 --value="$arg_nextcloud_domain"
			php occ config:system:set overwrite.cli.url --value="$arg_nextcloud_url"
			php occ config:system:set overwritehost --value="$arg_nextcloud_host"
			php occ config:system:set overwriteprotocol --value="$arg_nextcloud_protocol"

			mime_src="/tmp/main/config/mimetypemapping.json"
			mime_dest="/var/www/html/config/mimetypemapping.json"

			if [ -f "\$mime_src" ] && [ ! -f "\$mime_dest" ]; then
				info "$title: copy mimetypemapping.json"
				cp "\$mime_src" "\$mime_dest"
			fi
		SHELL
		;;
	"service:nextcloud:fs")
		"$pod_script_env_file" up "$arg_toolbox_service" "$arg_nextcloud_service"

		info "$title: nextcloud enable files_external"
		"$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" \
			php occ app:enable files_external

		info "$title - verify defined mounts"
		list="$("$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" \
			php occ files_external:list --output=json)" || error "service:nextcloud:fs - list"

		info "$title - count defined mounts with the mount point equal to $arg_mount_point"
		count="$(
			"$pod_script_env_file" exec-nontty "$arg_toolbox_service" /bin/bash \
				<<-'SHELL' -s "$list" "$arg_mount_point"
					set -eou pipefail
					echo "$1" | jq '[.[] | select(.mount_point == "'"$2"'")] | length'
				SHELL
		)" || error "service:nextcloud:fs - count"

		if [[ $count -eq 0 ]]; then
			info "$title: defining fs storage ($arg_mount_point)..."
			"$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" \
				php occ files_external:create "$arg_mount_point" \
				local --config datadir="${arg_datadir}" "null::null"
		else
			info "$title: fs storage already defined ($arg_mount_point)"
		fi
		;;
	"service:nextcloud:s3")
		"$pod_script_env_file" up "$arg_toolbox_service" "$arg_nextcloud_service"

		info "$title: nextcloud enable files_external"
		"$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" \
			php occ app:enable files_external

		info "$title - verify defined mounts"
		list="$("$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" \
			php occ files_external:list --output=json)" || error "service:nextcloud:s3 - list"

		info "$title - count defined mounts with the mount point equal to $arg_mount_point"
		count="$(
			"$pod_script_env_file" exec-nontty "$arg_toolbox_service" /bin/bash \
				<<-'SHELL' -s "$list" "$arg_mount_point"
					set -eou pipefail
					echo "$1" | jq '[.[] | select(.mount_point == "'"$2"'")] | length'
				SHELL
		)" || error "service:nextcloud:s3 - count"

		if [[ $count -eq 0 ]]; then
			info "$title: defining s3 storage ($arg_mount_point)..."
			"$pod_script_env_file" exec-nontty -u www-data "$arg_nextcloud_service" /bin/bash <<-SHELL
				set -eou pipefail

				php occ files_external:create "$arg_mount_point" \
					amazons3 \
						--config bucket="${arg_bucket}" \
						--config hostname="${arg_hostname:-}" \
						--config port="${arg_port:-}" \
						--config region="${arg_region:-}" \
						--config use_ssl="${arg_use_ssl:-}" \
						--config use_path_style="${arg_use_path_style:-}" \
						--config legacy_auth="${arg_legacy_auth:-}"  \
					amazons3::accesskey \
						--config key="$arg_key" \
						--config secret="$arg_secret"
			SHELL
		else
			info "$title: s3 storage already defined ($arg_mount_point)"
		fi
		;;
	*)
		error "$title: invalid title"
		;;
esac