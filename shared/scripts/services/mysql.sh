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
	"service:mysql:log:slow:summary")
		"$pod_script_env_file" exec-nontty "$arg_toolbox_service" /bin/bash <<-SHELL
			set -eou pipefail

			echo -e "##############################################################################################################"
			echo -e "##############################################################################################################"
			echo -e "MySQL - Slow Logs"
			echo -e "--------------------------------------------------------------------------------------------------------------"
			echo -e "Path: $arg_log_file"
			echo -e "Limit: $arg_max_amount"

			if [ -f "$arg_log_file" ]; then
				echo -e "--------------------------------------------------------------------------------------------------------------"

				mysql_qtd_slow_logs="\$( \
					{ grep '^# User@Host' "$arg_log_file" \
					| awk '{s[substr(\$3, 0, index(\$3, "[") - 1)]+=1} END { for (key in s) { printf "%10d %s\n", s[key], key } }' \
					| sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$mysql_qtd_slow_logs"

				echo -e "##############################################################################################################"
    			echo -e "MySQL - Slow Logs - Times with slowest logs per user"
				echo -e "--------------------------------------------------------------------------------------------------------------"

				mysql_slowest_logs_per_user="\$( \
					{ grep -E '^(# Time: |# User@Host: |# Query_time: )' "$arg_log_file" \
					| awk '
						{
							if(\$2 == "Time:") {time = \$3 " " \$4;}
							else if(\$2 == "User@Host:") {user = substr(\$3, 0, index(\$3, "[") - 1);}
							else if(\$2 == "Query_time:") {
							if(s[user] < \$3) { s[user] = \$3; t[user] = time; }
							}
						} END
						{ for (key in s) { printf "%10.1f %12s %s\n", s[key], key, t[key] } }
						' \
					| sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$mysql_slowest_logs_per_user"

				echo -e "##############################################################################################################"
    			echo -e "MySQL - Slow Logs - Times with slowest logs"
				echo -e "--------------------------------------------------------------------------------------------------------------"

				mysql_slowest_logs="\$( \
					{ grep -E '^(# Time: |# User@Host: |# Query_time: )' "$arg_log_file" \
					| awk '{ \
						if(\$2 == "Time:") {time = \$3 " " \$4;} \
						else if(\$2 == "User@Host:") {user = substr(\$3, 0, index(\$3, "[") - 1);} \
						else if(\$2 == "Query_time:") printf "%10.1f %12s %s\n", \$3, user, time }' \
					| sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$mysql_slowest_logs"
			fi
		SHELL
		;;
	*)
		error "$command: invalid command"
		;;
esac
