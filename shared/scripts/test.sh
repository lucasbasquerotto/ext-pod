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

case "$command" in
	"shared:test:zip")
		"$pod_script_env_file" up "toolbox"

		"$pod_script_env_file" exec-nontty "toolbox" /bin/bash <<-SHELL
			set -eou pipefail

			rm -rf /tmp/main/test/src/
			rm -rf /tmp/main/test/dest/
			mkdir -p /tmp/main/test/src/dir/
			mkdir -p /tmp/main/test/dest

			echo "\$(date '+%F %X') - test 1 ($$)" > /tmp/main/test/src/file1.txt
			echo "\$(date '+%F %X') - test 2 ($$)" > /tmp/main/test/src/dir/file2.txt
			echo "\$(date '+%F %X') - test 3 ($$)" > /tmp/main/test/src/dir/file3.txt
			echo "\$(date '+%F %X') - test 4 ($$)" > /tmp/main/test/src/dir/file4.txt

			mkdir -p /tmp/main/test/dest/
		SHELL

		"$pod_script_env_file" "compress:zip" \
			--task_name="test-1.1" \
			--subtask_cmd="$command" \
			--toolbox_service="toolbox" \
			--task_kind="file" \
			--src_file="/tmp/main/test/src/file1.txt" \
			--dest_file="/tmp/main/test/dest/file.zip"

		"$pod_script_env_file" "compress:zip" \
			--task_name="test-1.2" \
			--subtask_cmd="$command" \
			--toolbox_service="toolbox" \
			--task_kind="dir" \
			--src_dir="/tmp/main/test/src/dir" \
			--dest_file="/tmp/main/test/dest/dir.zip"

		"$pod_script_env_file" "compress:zip" \
			--task_name="test-1.3" \
			--subtask_cmd="$command" \
			--toolbox_service="toolbox" \
			--task_kind="dir" \
			--src_dir="/tmp/main/test/src/dir" \
			--dest_file="/tmp/main/test/dest/flat.zip" \
			--flat="true"

		"$pod_script_env_file" "compress:zip" \
			--task_name="test-1.4" \
			--subtask_cmd="$command" \
			--toolbox_service="toolbox" \
			--task_kind="file" \
			--src_file="/tmp/main/test/src/dir/file2.txt" \
			--dest_file="/tmp/main/test/dest/pass.zip" \
			--compress_pass="123456"
		;;
	"shared:test:unzip")
		"$pod_script_env_file" up "toolbox"


		"$pod_script_env_file" exec-nontty "toolbox" /bin/bash <<-SHELL
			set -eou pipefail

			rm -rf /tmp/main/test/newdest/

			mkdir -p /tmp/main/test/newdest/file
			mkdir -p /tmp/main/test/newdest/dir
			mkdir -p /tmp/main/test/newdest/flat
			mkdir -p /tmp/main/test/newdest/pass
		SHELL

		"$pod_script_env_file" "uncompress:zip" \
			--task_name="test-2.1" \
			--subtask_cmd="$command" \
			--toolbox_service="toolbox" \
			--src_file="/tmp/main/test/dest/file.zip" \
			--dest_dir="/tmp/main/test/newdest/file" \
			--compress_pass=""

		"$pod_script_env_file" "uncompress:zip" \
			--task_name="test-2.2" \
			--subtask_cmd="$command" \
			--toolbox_service="toolbox" \
			--src_file="/tmp/main/test/dest/dir.zip" \
			--dest_dir="/tmp/main/test/newdest/dir" \
			--compress_pass=""

		"$pod_script_env_file" "uncompress:zip" \
			--task_name="test-2.4" \
			--subtask_cmd="$command" \
			--toolbox_service="toolbox" \
			--src_file="/tmp/main/test/dest/flat.zip" \
			--dest_dir="/tmp/main/test/newdest/flat" \
			--compress_pass=""

		"$pod_script_env_file" "uncompress:zip" \
			--task_name="test-2.3" \
			--subtask_cmd="$command" \
			--toolbox_service="toolbox" \
			--src_file="/tmp/main/test/dest/pass.zip" \
			--dest_dir="/tmp/main/test/newdest/pass" \
			--compress_pass="123456"
		;;
	*)
		error "$command: invalid command"
		;;
esac
