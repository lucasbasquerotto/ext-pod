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
		nginx_service ) arg_nginx_service="${OPTARG:-}";;

		max_amount ) arg_max_amount="${OPTARG:-}";;

		output_file ) arg_output_file="${OPTARG:-}";;
		manual_file ) arg_manual_file="${OPTARG:-}";;
		allowed_hosts_file ) arg_allowed_hosts_file="${OPTARG:-}";;
		file_exclude_paths ) arg_file_exclude_paths="${OPTARG:-}";;
		log_file_day ) arg_log_file_day="${OPTARG:-}";;
		log_file_last_day ) arg_log_file_last_day="${OPTARG:-}";;
		amount_day ) arg_amount_day="${OPTARG:-}";;
		log_file_last_hour ) arg_log_file_last_hour="${OPTARG:-}";;
		log_file_hour ) arg_log_file_hour="${OPTARG:-}";;
		amount_hour ) arg_amount_hour="${OPTARG:-}";;

		log_file ) arg_log_file="${OPTARG:-}";;
		log_idx_ip ) arg_log_idx_ip="${OPTARG:-}";;
		log_idx_user ) arg_log_idx_user="${OPTARG:-}";;
		log_idx_http_user ) arg_log_idx_http_user="${OPTARG:-}";;
		log_idx_duration ) arg_log_idx_duration="${OPTARG:-}";;
		log_idx_status ) arg_log_idx_status="${OPTARG:-}";;
		log_idx_time ) arg_log_idx_time="${OPTARG:-}";;
		??* ) error "$command: Illegal option --$OPT" ;;  # bad long option
		\? )  exit 2 ;;  # bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1))

title="$command"
[ -n "${arg_task_name:-}" ] && title="$title - $arg_task_name"
[ -n "${arg_subtask_cmd:-}" ] && title="$title ($arg_subtask_cmd)"

case "$command" in
	"service:nginx:start")
		>&2 "$pod_script_env_file" up "$arg_nginx_service"
		>&2 "$pod_script_env_file" restart "$arg_nginx_service"
		;;
	"service:nginx:reload")
		>&2 "$pod_script_env_file" exec-nontty "$arg_nginx_service" nginx -s reload
		;;
	"service:nginx:block_ips")
		reload="$("$pod_script_env_file" exec-nontty "$arg_toolbox_service" /bin/bash <<-SHELL
			set -eou pipefail

			function info {
				msg="\$(date '+%F %T') - \${1:-}"
				>&2 echo -e "${GRAY}\${msg}${NC}"
			}

			function error {
				msg="\$(date '+%F %T') - \${BASH_SOURCE[0]}: line \${BASH_LINENO[0]}: \${1:-}"
				>&2 echo -e "${RED}\${msg}${NC}"
				exit 2
			}

			function invalid_cidr_network() {
				[[ "\$1" =~ ^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.)){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]] && echo "0" || echo "1"
			}

			function ipstoblock {
				nginx_file_path="\${1:-}"
				amount="\${2:-10}"
				ips_most_requests=''

				if [ -f "\$nginx_file_path" ]; then
					ips_most_requests=\$( \
						{ \
							awk '{print \$1}' "\$nginx_file_path" \
							| sort \
							| uniq -c \
							| sort -nr \
							| awk -v amount="\$amount" '{if(\$1 > amount) {printf "%s 1; # %s\n", \$2, \$1}}' \
							||:; \
						} \
						| head -n "$arg_max_amount" \
					)
				fi

				if [ -n "\$ips_most_requests" ]; then
					output=''

					while read -r i; do
						ip="\$(echo "\$i" | awk '{print \$1}')"
						invalid_ip="\$(invalid_cidr_network "\$ip")" ||:

						if [ "\${invalid_ip:-1}" = "1" ]; then
							>&2 echo "invalid ip: \$ip";
						else
							# include ip if it isn't already defined
							# it will be considered as defined even if it is commented
							if ! grep -qE "^(\$ip[ ]|[#]+[ ]*\$ip[ ])" "$arg_output_file"; then
								output_aux="\n\$i";

								# do nothing if ip already exists in manual file
								if [ -n "${arg_manual_file:-}" ] && [ -f "${arg_manual_file:-}" ]; then
									if grep -qE "^(\$ip|#[ ]*\$ip|##[ ]*\$ip)" "${arg_manual_file:-}"; then
										output_aux=''
									fi
								fi

								if [ -n "\$output_aux" ]; then
									host="\$(host "\$ip" | awk '{ print \$NF }' | sed 's/.\$//' ||:)"

									if [ -n "\$host" ] && [ -n "${arg_allowed_hosts_file:-}" ]; then
										regex="^[ ]*[^#^ ].*$"
										allowed_hosts="\$(grep -E "\$regex" "${arg_allowed_hosts_file:-}" ||:)"

										if [ -n "\$allowed_hosts" ]; then
											while read -r allowed_host; do
												if [[ \$host == \$allowed_host ]]; then
													ip_host="$(host "\$host" | awk '{ print $NF }' ||:)"

													if [ -n "\$ip_host" ] && [ "\$ip" = "\$ip_host" ]; then
														output_aux="\n## \$i (\$host)";
													fi

													break;
												fi
											done <<< "\$(echo -e "\$allowed_hosts")"
										fi
									fi
								fi

								output="\$output\$output_aux";
							fi
						fi
					done <<< "\$(echo -e "\$ips_most_requests")"

					if [ -n "\$output" ]; then
						output="#\$(TZ=GMT date '+%F %T')\$output"
						echo -e "\n\$output" | tee --append "$arg_output_file" > /dev/null
					fi
				fi
			}

			if [ ! -f "$arg_output_file" ]; then
				mkdir -p "${arg_output_file%/*}" && touch "$arg_output_file"
			fi

			iba1=\$(md5sum "$arg_output_file")

			if [ -n "${arg_log_file_last_day:-}" ] && [ -f "${arg_log_file_last_day:-}" ]; then
				if [ "${arg_amount_day:-}" -le "0" ]; then
					error "$command: amount_day (${arg_amount_day:-}) should be greater than 0"
				fi

				info "$command: define ips to block (more than ${arg_amount_day:-} requests in the last day) - ${arg_log_file_last_day:-}"
				ipstoblock "${arg_log_file_last_day:-}" "${arg_amount_day:-}"
			fi

			if [ -n "${arg_log_file_day:-}" ] && [ -f "${arg_log_file_day:-}" ]; then
				if [ "${arg_amount_day:-}" -le "0" ]; then
					error "$command: amount_day (${arg_amount_day:-}) should be greater than 0"
				fi

				info "$command: define ips to block (more than ${arg_amount_day:-} requests in a day) - ${arg_log_file_day:-}"
				ipstoblock "${arg_log_file_day:-}" "${arg_amount_day:-}"
			fi

			if [ -n "${arg_log_file_last_hour:-}" ] && [ -f "${arg_log_file_last_hour:-}" ]; then
				if [ "${arg_amount_hour:-}" -le "0" ]; then
					error "$command: amount_hour (${arg_amount_hour:-}) should be greater than 0"
				fi

				info "$command: define ips to block (more than ${arg_amount_hour:-} requests in the last hour) - ${arg_log_file_last_hour:-}"
				ipstoblock "${arg_log_file_last_hour:-}" "${arg_amount_hour:-}"
			fi

			if [ -n "${arg_log_file_hour:-}" ] && [ -f "${arg_log_file_hour:-}" ]; then
				if [ "${arg_amount_hour:-}" -le "0" ]; then
					error "$command: amount_hour (${arg_amount_hour:-}) should be greater than 0"
				fi

				info "$command: define ips to block (more than ${arg_amount_hour:-} requests in an hour) - ${arg_log_file_hour:-}"
				ipstoblock "${arg_log_file_hour:-}" "${arg_amount_hour:-}"
			fi

			iba2=\$(md5sum "$arg_output_file")

			if [ "\$iba1" != "\$iba2" ]; then
				echo "true"
			else
				echo "false"
			fi
		SHELL
		)"

		if [ "$reload" = "true" ]; then
			>&2 "$pod_script_env_file" "service:nginx:reload" --nginx_service="$arg_nginx_service"
		fi
		;;
	"service:nginx:log:summary:total")
		"$pod_script_env_file" exec-nontty "$arg_toolbox_service" /bin/bash <<-SHELL
			set -eou pipefail

			request_count="\$(wc -l < "$arg_log_file")"
			echo -e "Requests: \$request_count"

			if [ -n "${arg_log_idx_user:-}" ]; then
				total_users="\$(awk -v idx="${arg_log_idx_user:-}" '{print \$idx}' "$arg_log_file" | sort | uniq -c | wc -l)"
				echo -e "Users: \$total_users"
			fi

			if [ -n "${arg_log_idx_http_user:-}" ]; then
				total_http_users="\$(awk -v idx="${arg_log_idx_http_user:-}" '{print \$idx}' "$arg_log_file" | sort | uniq -c | wc -l)"
				echo -e "HTTP Users: \$total_http_users"
			fi

			if [ -n "${arg_log_idx_duration:-}" ]; then
				total_duration="\$(awk -v idx="${arg_log_idx_duration:-}" '{s+=\$idx} END {print s}' "$arg_log_file")"
				echo -e "Duration: \$total_duration"
			fi

			if [ -n "${arg_log_idx_ip:-}" ]; then
				echo -e "#######################################################"
				echo -e "Ips with Most Requests"
				echo -e "-------------------------------------------------------"

				ips_most_requests="\$( \
					{ awk -v idx="${arg_log_idx_ip:-}" '{print \$idx}' "$arg_log_file" \
					| sort | uniq -c | sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$ips_most_requests"
			fi

			if [ -n "${arg_log_idx_ip:-}" ] && [ -n "${arg_log_idx_duration:-}" ]; then
				echo -e "======================================================="
				echo -e "IPs with Most Request Duration (s)"
				echo -e "-------------------------------------------------------"

				ips_most_request_duration="\$( \
					{ awk -v idx_ip="${arg_log_idx_ip:-}" -v idx_duration="${arg_log_idx_duration:-}" \
						'{s[\$idx_ip]+=\$idx_duration} END { for (key in s) { printf "%10.1f %s\n", s[key], key } }' \
						"$arg_log_file" \
					| sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$ips_most_request_duration"
			fi

			if [ -n "${arg_log_idx_user:-}" ]; then
				echo -e "======================================================="
				echo -e "Users with Most Requests"
				echo -e "-------------------------------------------------------"

				users_most_requests="\$( { awk -v idx="${arg_log_idx_user:-}" \
					'{print \$idx}' "$arg_log_file" \
					| sort | uniq -c | sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$users_most_requests"
			fi

			if [ -n "${arg_log_idx_user:-}" ] && [ -n "${arg_log_idx_duration:-}" ]; then
				echo -e "======================================================="
				echo -e "Users with Most Request Duration (s)"
				echo -e "-------------------------------------------------------"

				users_most_request_duration="\$( \
					{ awk -v idx_user="${arg_log_idx_user:-}" -v idx_duration="${arg_log_idx_duration:-}" \
						'{s[\$idx_user]+=\$idx_duration} END { for (key in s) { printf "%10.1f %s\n", s[key], key } }' \
						"$arg_log_file" \
					| sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$users_most_request_duration"
			fi

			if [ -n "${arg_log_idx_status:-}" ]; then
				echo -e "======================================================="
				echo -e "Status with Most Requests"
				echo -e "-------------------------------------------------------"

				status_most_requests="\$( \
					{ awk -v idx="${arg_log_idx_status:-}" '{print \$idx}' "$arg_log_file" \
					| sort | uniq -c | sort -nr ||:; } | head -n "$arg_max_amount")"
				echo -e "\$status_most_requests"
			fi

			if [ -n "${arg_log_idx_duration:-}" ]; then
				echo -e "======================================================="
				echo -e "Requests with Longest Duration (s)"
				echo -e "-------------------------------------------------------"

				grep_args=()

				if [ -n "${arg_file_exclude_paths:-}" ] && [ -f "${arg_file_exclude_paths:-}" ]; then
					regex="^[ ]*[^#^ ].*$"
					grep_lines="\$(grep -E "\$regex" "${arg_file_exclude_paths:-}" ||:)"

					if [ -n "\$grep_lines" ]; then
						while read -r grep_line; do
							if [ "\${#grep_args[@]}" -eq 0 ]; then
								grep_args=( "-v" )
							fi

							grep_args+=( "-e" "\$grep_line" )
						done <<< "\$(echo -e "\$grep_lines")"
					fi
				fi

				if [ "\${#grep_args[@]}" -eq 0 ]; then
					grep_args=( "." )
				fi

				longest_request_durations="\$( \
					grep \${grep_args[@]+"\${grep_args[@]}"} "$arg_log_file" \
					| { awk \
						-v idx_ip="${arg_log_idx_ip:-}" \
						-v idx_user="${arg_log_idx_user:-}" \
						-v idx_duration="${arg_log_idx_duration:-}" \
						-v idx_time="${arg_log_idx_time:-}" \
						-v idx_status="${arg_log_idx_status:-}" \
						'{ printf "%10.1f %s %s %s %s\n", \
							\$idx_duration, \
							substr(\$idx_time, index(\$idx_time, ":") + 1), \
							\$idx_status, \
							\$idx_user, \
							\$idx_ip }' \
						| sort -nr ||:; } \
					| head -n "$arg_max_amount")"
				echo -e "\$longest_request_durations"
			fi
		SHELL
		;;
	"service:nginx:log:duration")
		"$pod_script_env_file" exec-nontty "$arg_toolbox_service" /bin/bash <<-SHELL
			set -eou pipefail

			if [ -n "${arg_log_idx_duration:-}" ]; then
				echo -e "======================================================="
				echo -e "Requests with Longest Duration (s) - Full"
				echo -e "-------------------------------------------------------"

				grep_args=()

				if [ -n "${arg_file_exclude_paths:-}" ] && [ -f "${arg_file_exclude_paths:-}" ]; then
					regex="^[ ]*[^#^ ].*$"
					grep_lines="\$(grep -E "\$regex" "${arg_file_exclude_paths:-}" ||:)"

					if [ -n "\$grep_lines" ]; then
						while read -r grep_line; do
							if [ "\${#grep_args[@]}" -eq 0 ]; then
								grep_args=( "-v" )
							fi

							grep_args+=( "-e" "\$grep_line" )
						done <<< "\$(echo -e "\$grep_lines")"
					fi
				fi

				if [ "\${#grep_args[@]}" -eq 0 ]; then
					grep_args=( "." )
				fi

				longest_request_durations="\$( \
					grep \${grep_args[@]+"\${grep_args[@]}"} "$arg_log_file" \
					| { awk \
						-v idx_duration="${arg_log_idx_duration:-}" \
						'{ printf "%10.1f %s\n", \$idx_duration, \$0 }' \
						| sort -nr ||:; } \
					| head -n "$arg_max_amount")"
				echo -e "\$longest_request_durations"
			fi
		SHELL
		;;
	*)
		error "$command: invalid command"
		;;
esac