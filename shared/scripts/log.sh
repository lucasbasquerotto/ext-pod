#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC1117,SC2153,SC2214
set -eou pipefail

pod_vars_dir="$POD_VARS_DIR"
pod_layer_dir="$POD_LAYER_DIR"
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

lib_dir="$pod_layer_dir/$var_shared__script_dir/lib"

while getopts ':-:' OPT; do
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"       # extract long option name
		OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		subtask_cmd ) arg_subtask_cmd="${OPTARG:-}";;
		summary_name ) arg_summary_name="${OPTARG:-}";;
		days_ago ) arg_days_ago="${OPTARG:-}";;
		max_amount ) arg_max_amount="${OPTARG:-}";;
		force ) arg_force="${OPTARG:-}";;
		cmd ) arg_cmd="${OPTARG:-}";;
		log_dir ) arg_log_dir="${OPTARG:-}";;
		log_file ) arg_log_file="${OPTARG:-}";;
		filename_prefix ) arg_filename_prefix="${OPTARG:-}";;
		verify_size_docker_dir ) arg_verify_size_docker_dir="${OPTARG:-}";;
		verify_size_containers ) arg_verify_size_containers="${OPTARG:-}";;
		??* ) ;; ## ignore
		\? )  ;; ## ignore
	esac
done
shift $((OPTIND-1))

case "$command" in
	"shared:log:memory_overview:summary")
		"$pod_script_env_file" "shared:log:summary" \
			--summary_name="memory_overview" \
			--cmd="shared:log:memory_overview:summary:log" \
			--subtask_cmd="$command" \
			--days_ago="${arg_days_ago:-}" \
			--max_amount="${arg_max_amount:-}"
        ;;
	"shared:log:summary")
		max_amount_var_name="var_shared__log__${arg_summary_name}__max_amount"
        max_amount="${!max_amount_var_name:-}"
        max_amount="${arg_max_amount:-$max_amount}"
        max_amount="${max_amount:-100}"

		path_prefix="/var/log/main/register/$arg_summary_name/$arg_summary_name"
		[ -n "${arg_days_ago:-}" ] && date_arg="${arg_days_ago:-} day ago" || date_arg="today"
		date="$(date -u -d "$date_arg" '+%Y-%m-%d')"
		log_file="$path_prefix.$date.out.log"

		"$pod_script_env_file" "$arg_cmd" \
			--task_name="summary_$arg_summary_name" \
			--subtask_cmd="$arg_subtask_cmd" \
			--log_file="$log_file" \
			--max_amount="$max_amount"
        ;;
	"shared:log:memory_overview:summary:log")
		"$pod_script_env_file" exec-nontty toolbox /bin/bash <<-SHELL
			set -eou pipefail

			echo -e "##############################################################################################################"
			echo -e "##############################################################################################################"
			echo -e "Memory Overview Logs"
			echo -e "--------------------------------------------------------------------------------------------------------------"
			echo -e "Path: $arg_log_file"
			echo -e "Limit: $arg_max_amount"

			if [ -f "$arg_log_file" ]; then
				echo -e "--------------------------------------------------------------------------------------------------------------"

				memory_max_logs="\$( \
					{ grep -E '^(Time: |Mem: )' "$arg_log_file" \
					| awk '{
						if(\$1 == "Time:") {time = \$2 " " \$3 " " \$4;}
						else if(\$1 == "Mem:" && NF == 7) { printf "%10d %s\n", \$3, time }
						}' \
					| sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$memory_max_logs"
			fi
		SHELL
		;;
	"shared:log:nginx:summary")
		"$pod_script_env_file" "shared:log:nginx:verify"

		dest_day_file="$("$pod_script_env_file" "shared:log:nginx:day" \
			--force="${arg_force:-}" \
			--days_ago="${arg_days_ago:-}")"

		nginx_sync_base_dir="/var/main/data/sync/nginx"
        max_amount="${var_shared__log__nginx_summary__max_amount:-}"
        max_amount="${arg_max_amount:-$max_amount}"
        max_amount="${max_amount:-100}"

		"$pod_script_env_file" "service:nginx:log:summary:total" \
			--task_name="nginx_log" \
			--subtask_cmd="$command" \
			--log_file="$dest_day_file" \
            --file_exclude_paths="$nginx_sync_base_dir/manual/log-exclude-paths.conf" \
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
		dest_base_path="/var/log/main/nginx/main"

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
        max_amount="${max_amount:-100}"

		"$pod_script_env_file" "service:nginx:log:duration" \
			--task_name="nginx_duration" \
			--subtask_cmd="$command" \
			--log_file="$dest_day_file" \
            --file_exclude_paths="$nginx_sync_base_dir/manual/log-exclude-paths-full.conf" \
			--log_idx_duration="3" \
			--max_amount="$max_amount"
        ;;
	"shared:log:nginx:summary:connections")
		"$pod_script_env_file" "shared:log:nginx:verify"

		"$pod_script_env_file" "shared:log:summary" \
			--summary_name="nginx_basic_status" \
			--cmd="service:nginx:log:connections" \
			--subtask_cmd="$command" \
			--days_ago="${arg_days_ago:-}" \
			--max_amount="${arg_max_amount:-}"
        ;;
	"shared:log:register:"*)
		task_name="${command#shared:log:register:}"
		"$pod_script_env_file" "shared:log:register" \
			--cmd="shared:log:main:$task_name" \
			--log_dir="/var/log/main/register/$task_name" \
			--filename_prefix="$task_name"
		;;
	"shared:log:register")
		log="$("$pod_script_env_file" "$arg_cmd")" || error "$command: $arg_cmd"

		"$pod_script_env_file" exec-nontty toolbox /bin/bash <<-SHELL
			set -eou pipefail

			log_file_prefix="$arg_log_dir/$arg_filename_prefix.\$(date '+%Y-%m-%d')"
			log_out_file="\${log_file_prefix}.out.log"
			log_err_file="\${log_file_prefix}.err.log"
			mkdir -p "$arg_log_dir"
			echo -e "Time: \$(date '+%Y-%m-%d %T')\n$log\n" \
				> >(tee --append "\$log_out_file") \
				2> >(tee --append "\$log_err_file" >&2)
			find "$arg_log_dir" -empty -type f -delete
		SHELL
		;;
	"shared:log:main:nginx_basic_status")
		"$pod_script_env_file" exec-nontty toolbox curl -sL "http://nginx:9081/nginx/basic_status"
		;;
	"shared:log:main:memory_overview")
		free -m
		;;
	"shared:log:main:memory_details")
		if result="$(python3 "$lib_dir/ps_mem.py" 2>&1 ||:)"; then
			echo "$result"
		else
			echo "$result" >&2
			exit 1
		fi
		;;
	"shared:log:file_descriptors:summary")
		echo -e "======================================================="
		echo -e "File Descriptors"
		echo -e "-------------------------------------------------------"
		cd /proc
		for pid in [0-9]*; do
			echo "PID = $pid with $(sudo ls "/proc/$pid/fd/" 2>/dev/null | wc -l) file descriptors";
		done | sort -rn -k5 | head | while read -r _ _ pid _ fdcount _; do
			cmd="$(ps -o cmd -p "$pid" hc)"
			printf "%6d - %s - pid = %s\n" "$fdcount" "$cmd" "$pid"
		done | head -n "$arg_max_amount" || :
		;;
	"shared:log:disk:summary")
		echo -e "======================================================="
		echo -e "Disk Usage"
		echo -e "-------------------------------------------------------"
		df -h | grep -E '(^Filesystem|/$)'

		"$pod_script_env_file" exec-nontty toolbox /bin/bash <<-SHELL
			set -eou pipefail

			echo -e "-------------------------------------------------------"
			du -sh /var/main/data/ 2> /dev/null || :
			echo -e "-------------------------------------------------------"
			du -sh /var/main/data/* 2> /dev/null || :
			echo -e "-------------------------------------------------------"
			du -sh /var/log/main/ 2> /dev/null || :
			echo -e "-------------------------------------------------------"
			du -sh /var/log/main/* 2> /dev/null || :
			echo -e "-------------------------------------------------------"
			du -sh /tmp/main/ 2> /dev/null || :
			echo -e "-------------------------------------------------------"
			du -sh /tmp/main/* 2> /dev/null || :
		SHELL

		if [ "${arg_verify_size_docker_dir:-}" = "true" ]; then
			echo -e "-------------------------------------------------------"
			du -sh /var/lib/docker/ 2> /dev/null || :
			echo -e "-------------------------------------------------------"
			docker system df \
				| grep -E '^(TYPE|Images|Containers|Local Volumes)' \
				| sed -e 's/Local Volumes/Volumes      /g' \
				| awk '{ printf "%-12s %8s %10s    %-12s\n", $1, $2, $3, $4; }'
		fi

		if [ "${arg_verify_size_containers:-}" = "true" ]; then
			echo -e "-------------------------------------------------------"
			"$pod_script_env_file" "system:df"
		fi
		;;
	*)
		error "$command: invalid command"
		;;
esac
