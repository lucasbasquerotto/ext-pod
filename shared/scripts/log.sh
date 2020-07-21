#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC1117,SC2153,SC2214
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_script_env_file="$POD_SCRIPT_ENV_FILE"

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
	error "No command entered (env - shared)."
fi

shift;

while getopts ':-:' OPT; do
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		days_ago ) arg_days_ago="${OPTARG:-}";;
		force ) arg_force="${OPTARG:-}";;
		max_amount ) arg_max_amount="${OPTARG:-}";;
		??* ) ;; ## ignore
		\? )  ;; ## ignore
	esac
done
shift $((OPTIND-1))

case "$command" in
	"shared:log:nginx:summary")
		"$pod_script_env_file" "shared:log:nginx:verify"

		dest_day_file="$("$pod_script_env_file" "shared:log:nginx:day" \
			--force="${arg_force:-}" \
			--days_ago="${arg_days_ago:-}")"

		nginx_sync_base_dir="/var/main/data/sync/nginx"
        max_amount="${var_shared__log__nginx_summary__max_amount:-}"
        max_amount="${arg_max_amount:-$max_amount}"

		"$pod_script_env_file" "service:nginx:log:summary:total" \
			--task_name="nginx_log" \
			--subtask_cmd="$command" \
			--log_file="$dest_day_file" \
            --file_exclude_paths="$nginx_sync_base_dir/manual/log_exclude_paths.conf" \
			--log_idx_ip="1" \
			--log_idx_user="2" \
			--log_idx_duration="3" \
			--log_idx_status="4" \
			--log_idx_http_user="5" \
			--log_idx_time="6" \
			--max_amount="$max_amount"
		;;
	"shared:log:nginx:day")
		"$pod_script_env_file" "shared:log:nginx:verify"

		log_hour_path_prefix="$("$pod_script_env_file" "shared:log:nginx:hour_path_prefix")"
		dest_base_path="/var/log/main/nginx"

		"$pod_script_env_file" exec-nontty toolbox /bin/bash <<-SHELL
			set -eou pipefail

			[ -n "${arg_days_ago:-}" ] && date_arg="${arg_days_ago:-} day ago" || date_arg="today"
			date="\$(date -u -d "\$date_arg" '+%Y-%m-%d')"
			log_day_src_path_prefix="$log_hour_path_prefix.\$date"
			dest_day_file="${dest_base_path}/nginx.\$date.log"

			>&2 mkdir -p "$dest_base_path"

			if [ -f "\$dest_day_file" ]; then
				if [ ! "${arg_force:-}" = "true" ]; then
					echo "\$dest_day_file"
					exit 0
				fi

				>&2 rm -f "\$dest_day_file"
			fi

			for i in \$(seq -f "%02g" 1 24); do
				log_day_src_path_aux="\$log_day_src_path_prefix.\$i.log"

				if [ -f "\$log_day_src_path_aux" ]; then
					cat "\$log_day_src_path_aux" >> "\$dest_day_file"
				fi
			done

			if [ ! -f "\$dest_day_file" ]; then
				>&2 touch "\$dest_day_file"
			fi

			echo "\$dest_day_file"
		SHELL
		;;
	"shared:log:nginx:verify")
		case "$var_custom__pod_type" in
			"app"|"web")
				;;
			*)
				error "$command: pod_type ($var_custom__pod_type) not supported"
				;;
		esac

		if [ "${var_custom__use_fluentd:-}" != "true" ]; then
			error "$command: fluentd must be used"
		fi
		;;
	"shared:log:nginx:hour_path_prefix")
		log_hour_path_prefix="/var/log/main/fluentd/main/docker.nginx/docker.nginx.stdout"
		echo "$log_hour_path_prefix"
		;;
	"shared:log:nginx:duration")
		"$pod_script_env_file" "shared:log:nginx:verify"

		dest_day_file="$("$pod_script_env_file" "shared:log:nginx:day" \
			--force="${arg_force:-}" \
			--days_ago="${arg_days_ago:-}")"

		nginx_sync_base_dir="/var/main/data/sync/nginx"
        max_amount="${var_shared__log__nginx_duration__max_amount:-}"
        max_amount="${arg_max_amount:-$max_amount}"

		"$pod_script_env_file" "service:nginx:log:duration" \
			--task_name="nginx_duration" \
			--subtask_cmd="$command" \
			--log_file="$dest_day_file" \
            --file_exclude_paths="$nginx_sync_base_dir/manual/log_exclude_paths_full.conf" \
			--log_idx_duration="3" \
			--max_amount="$max_amount"
        ;;
	"shared:log:nginx:basic_status")
		"$pod_script_env_file" exec-nontty toolbox curl -sL "http://nginx:9080/nginx/basic_status"
		;;
	*)
		error "$command: invalid command"
		;;
esac
