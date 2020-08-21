#!/bin/bash
set -eou pipefail

# shellcheck disable=SC2153
pod_script_env_file="$POD_SCRIPT_ENV_FILE"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: ${*}"
}

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered."
fi

shift;

# shellcheck disable=SC2214
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
		redis_service ) arg_redis_service="${OPTARG:-}";;
		max_amount ) arg_max_amount="${OPTARG:-}";;
		log_file ) arg_log_file="${OPTARG:-}";;
		??* ) error "$command: Illegal option --$OPT" ;;  # bad long option
		\? )  exit 2 ;;  # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1))

title="$command"
[ -n "${arg_task_name:-}" ] && title="$title - $arg_task_name"
[ -n "${arg_subtask_cmd:-}" ] && title="$title ($arg_subtask_cmd)"

case "$command" in
	"service:redis:log:slow")
		len="$("$pod_script_env_file" exec-nontty "$arg_redis_service" redis-cli SLOWLOG LEN)"

		if [[ "$len" -gt 0 ]];then
			echo -e "======================================================================="
			echo -e "Started at $(date '+%Y-%m-%d %T')"
			echo -e "-----------------------------------------------------------------------"

			logs="$("$pod_script_env_file" exec-nontty "$arg_redis_service" redis-cli SLOWLOG GET "$arg_max_amount")"
			max=false

			if [[ "$len" -ge "$arg_max_amount" ]];then
				max=true
			fi

			"$pod_script_env_file" exec-nontty "$arg_redis_service" redis-cli SLOWLOG RESET

			echo -e "Time: $(date '+%Y-%m-%d %T')"
			echo -e "Amount: $len"
			echo -e "Maximum reached: $max"
			echo -e "-----------------------------------------------------------------------"
			echo -e "$logs"
			echo -e "-----------------------------------------------------------------------"
			echo -e "Ended at $(date '+%Y-%m-%d %T')"
			echo -e "======================================================================="
		fi
		;;
	"service:redis:log:slow:summary")
		"$pod_script_env_file" exec-nontty "$arg_toolbox_service" /bin/bash <<-SHELL || error "$command"
			set -eou pipefail

			echo -e "##############################################################################################################"
			echo -e "##############################################################################################################"
			echo -e "Redis - Slow Logs"
			echo -e "--------------------------------------------------------------------------------------------------------------"
			echo -e "Path: $arg_log_file"
			echo -e "Limit: $arg_max_amount"

			if [ -f "$arg_log_file" ]; then
				echo -e "--------------------------------------------------------------------------------------------------------------"

				redis_qtd_verifications="\$(grep -c '^Amount: ' "$arg_log_file")"
				redis_qtd_slow_logs="\$(grep '^Amount: ' "$arg_log_file" | awk '{s+=\$2} END { printf s }')"
				redis_qtd_slow_logs_max="\$(grep -c '^Maximum reached: true\$' "$arg_log_file" || :)"
				echo -e "Total Verifications: \$redis_qtd_verifications"
				echo -e "Total Amount: \$redis_qtd_slow_logs"
				echo -e "Total Amount Max Reached: \$redis_qtd_slow_logs_max"

				echo -e "##############################################################################################################"
    			echo -e "Redis - Slow Logs - Times with most slow logs"
				echo -e "--------------------------------------------------------------------------------------------------------------"

				redis_times_most_slow_logs="\$( \
					{ grep -E '^(Time: |Amount: |Maximum reached: )' "$arg_log_file" \
					| awk 'NR%3{printf "%s >>> ",\$0;next;next;}1' \
					| grep -v 'Amount: 0' \
					| awk '{printf "%7d %s at %s\n", \$7, \$2, \$4}' \
					| sort -g -r ||:; } | head -n "$arg_max_amount")"
				echo -e "\$redis_times_most_slow_logs"
			fi
		SHELL
		;;
	*)
		error "$command: invalid command"
		;;
esac
