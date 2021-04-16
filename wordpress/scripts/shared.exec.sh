#!/bin/bash
set -eou pipefail

# shellcheck disable=SC2154
pod_script_env_file="$var_pod_script"

function info {
	"$pod_script_env_file" "util:info" --info="${*}"
}

function error {
	"$pod_script_env_file" "util:error" --error="${BASH_SOURCE[0]}:${BASH_LINENO[0]}: ${*}"
}

trap 'echo "[error] ${BASH_SOURCE[0]}:$LINENO"; exit $LINENO;' ERR

command="${1:-}"

if [ -z "$command" ]; then
	error "No command entered (env - shared)."
fi

shift;

args=( "$@" )

# shellcheck disable=SC2214
while getopts ':-:' OPT; do
	if [ "$OPT" = "-" ]; then	 # long option: reformulate OPT and OPTARG
		OPT="${OPTARG%%=*}"			 # extract long option name
		OPTARG="${OPTARG#$OPT}"	 # extract long option argument (may be empty)
		OPTARG="${OPTARG#=}"			# if long option argument, remove assigning `=`
	fi
	case "$OPT" in
		task_info ) arg_task_info="${OPTARG:-}";;
		setup_url ) arg_setup_url="${OPTARG:-}";;
		setup_title ) arg_setup_title="${OPTARG:-}";;
		setup_admin_user ) arg_setup_admin_user="${OPTARG:-}";;
		setup_admin_password ) arg_setup_admin_password="${OPTARG:-}";;
		setup_admin_email ) arg_setup_admin_email="${OPTARG:-}";;
		setup_restore_seed ) arg_setup_restore_seed="${OPTARG:-}";;
		setup_local_seed_data ) arg_setup_local_seed_data="${OPTARG:-}";;
		setup_remote_seed_data ) arg_setup_remote_seed_data="${OPTARG:-}";;
		wp_activate_all_plugins ) arg_wp_activate_all_plugins="${OPTARG:-}";;
		wp_plugins_to_activate ) arg_wp_plugins_to_activate="${OPTARG:-}";;
		wp_plugins_to_deactivate ) arg_wp_plugins_to_deactivate="${OPTARG:-}";;
		old_domain_host ) arg_old_domain_host="${OPTARG:-}";;
		new_domain_host ) arg_new_domain_host="${OPTARG:-}";;
		wp_rewrite_structure ) arg_wp_rewrite_structure="${OPTARG:-}";;
		use_w3tc ) arg_use_w3tc="${OPTARG:-}";;
		use_varnish ) arg_use_varnish="${OPTARG:-}";;
		use_redis ) arg_use_redis="${OPTARG:-}";;
		use_memcached ) arg_use_memcached="${OPTARG:-}";;
		use_s3_storage ) arg_use_s3_storage="${OPTARG:-}";;
		??* ) error "Illegal option --$OPT" ;;	# bad long option
		\? )	exit 2 ;;	# bad short option (error reported via getopts)
	esac
done
shift $((OPTIND-1))

case "$command" in
	"setup:new")
		"$pod_script_env_file" up wordpress

		# Deploy a brand-new Wordpress site (with possibly seeded data)
		info "$command - installation"
		"$pod_script_env_file" exec-nontty wordpress \
			wp --allow-root core install \
			--url="$arg_setup_url" \
			--title="$arg_setup_title" \
			--admin_user="$arg_setup_admin_user" \
			--admin_password="$arg_setup_admin_password" \
			--admin_email="$arg_setup_admin_email"

		if [ "${arg_setup_restore_seed:-}" = "true" ]; then
			if [ -z "$arg_setup_local_seed_data" ] && [ -z "$arg_setup_remote_seed_data" ]; then
				error "$command - seed_data not provided"
			else
				info "$command - migrate..."
				"$pod_script_env_file" migrate --task_info="${arg_task_info:-}"

				if [ -n "$arg_setup_local_seed_data" ]; then
					info "$command - import local seed data"
					"$pod_script_env_file" exec-nontty wordpress \
						wp --allow-root import ./"$arg_setup_local_seed_data" --authors=create
				fi

				if [ -n "$arg_setup_remote_seed_data" ]; then
					info "$command - import remote seed data"
					"$pod_script_env_file" exec-nontty wordpress /bin/bash <<-SHELL || error "$command"
						curl -L -o ./tmp/tmp-seed-data.xml -k "$arg_setup_remote_seed_data" \
							&& wp --allow-root import ./tmp/tmp-seed-data.xml --authors=create \
							&& rm -f ./tmp/tmp-seed-data.xml
					SHELL
				fi
			fi
		fi
		;;
	"migrate:app")
		"$pod_script_env_file" "migrate:db" ${args[@]+"${args[@]}"}
		"$pod_script_env_file" "migrate:web" ${args[@]+"${args[@]}"}
		;;
	"migrate:db")
		info "$command - nothing to do..."
		;;
	"migrate:web")
		s3_plugins='amazon-s3-and-cloudfront amazon-s3-and-cloudfront-tweaks'

		info "$command - start container"
		"$pod_script_env_file" up wordpress

		"$pod_script_env_file" exec-nontty wordpress /bin/bash <<-SHELL || error "$command"
			set -eou pipefail

			>&2 echo "update database"
			wp --allow-root core update-db
			wp --allow-root core is-installed
			version="\$(wp --allow-root core version)"
			>&2 echo "wordpress version: \$version"

			if [ "${arg_use_w3tc:-}" = "true" ]; then
				>&2 echo "activate plugin: w3tc"
				wp --allow-root plugin activate w3-total-cache
				>&2 echo "plugin activated: w3tc"

				if [ "${arg_use_redis:-}" = "true" ]; then
					cp /var/www/html/web/app/plugins/w3-total-cache/wp-content/object-cache.php \
						/var/www/html/web/app/object-cache.php

					>&2 echo "w3tc: db cache: redis"
					wp --allow-root w3-total-cache option set dbcache.enabled true --type=boolean
					wp --allow-root w3-total-cache option set dbcache.engine redis
					wp --allow-root w3-total-cache option set dbcache.redis.servers 'redis:6379'

					>&2 echo "w3tc: object cache: redis"
					wp --allow-root w3-total-cache option set objectcache.enabled true --type=boolean
					wp --allow-root w3-total-cache option set objectcache.engine redis
					wp --allow-root w3-total-cache option set objectcache.redis.servers 'redis:6379'

					>&2 echo "w3tc: redis - end"
				elif [ "${arg_use_memcached:-}" = "true" ]; then
					cp /var/www/html/web/app/plugins/w3-total-cache/wp-content/object-cache.php \
						/var/www/html/web/app/object-cache.php

					>&2 echo "w3tc: db cache: memcached"
					wp --allow-root w3-total-cache option set dbcache.enabled true --type=boolean
					wp --allow-root w3-total-cache option set dbcache.engine memcached
					wp --allow-root w3-total-cache option set dbcache.memcached.servers 'memcached:11211'

					>&2 echo "w3tc: object cache: memcached"
					wp --allow-root w3-total-cache option set objectcache.enabled true --type=boolean
					wp --allow-root w3-total-cache option set objectcache.engine memcached
					wp --allow-root w3-total-cache option set objectcache.memcached.servers 'memcached:11211'

					>&2 echo "w3tc: memcached - end"
				else
					wp --allow-root w3-total-cache option set dbcache.enabled false --type=boolean
					wp --allow-root w3-total-cache option set objectcache.enabled false --type=boolean
				fi

				>&2 echo "w3tc: verify if page cache can use apcu"
				has_apcu="\$(php -m | grep -c apcu ||:)"

				if [ "\$has_apcu" = "1" ]; then
					>&2 echo "w3tc: page cache: apcu (start)"
					wp --allow-root w3-total-cache option set pgcache.enabled true --type=boolean
					wp --allow-root w3-total-cache option set pgcache.engine apc
					>&2 echo "w3tc: page cache: apcu (end)"
				fi

				if [ "${arg_use_varnish:-}" = "true" ]; then
					>&2 echo "w3tc: enable varnish"
					wp --allow-root w3-total-cache option set varnish.enabled true --type=boolean
					wp --allow-root w3-total-cache option set varnish.servers 'varnish'
					>&2 echo "w3tc: varnish enabled"
				fi
			fi

			if [ "${arg_wp_activate_all_plugins:-}" = "true" ]; then
				>&2 echo "activate all plugins"
				wp --allow-root plugin activate --all
			elif [ -n "${arg_wp_plugins_to_activate:-}" ]; then
				>&2 echo "activate specified plugins: ${arg_wp_plugins_to_activate:-}"
				wp --allow-root plugin activate ${arg_wp_plugins_to_activate:-} \
					&& error="0" || error="1"

				if [ "\$error" != "0" ]; then
					>&2 echo "ignore previous error and activate specified plugins"
					wp --allow-root plugin activate ${arg_wp_plugins_to_activate:-}
					>&2 echo "specified plugins activated"
				fi
			fi

			if [ -n "${arg_wp_plugins_to_deactivate:-}" ]; then
				>&2 echo "deactivate specified plugins: ${arg_wp_plugins_to_deactivate:-}"
				wp --allow-root plugin deactivate ${arg_wp_plugins_to_deactivate:-} \
					&& error="0" || error="1"

				if [ "\$error" != "0" ]; then
					>&2 echo "ignore previous error and deactivate specified plugins"
					wp --allow-root plugin deactivate ${arg_wp_plugins_to_deactivate:-}
					>&2 echo "specified plugins deactivated"
				fi
			fi

			if [ -n "${arg_old_domain_host:-}" ] && [ -n "${arg_new_domain_host:-}" ]; then
				>&2 echo "update domain"
				wp --allow-root search-replace "$arg_old_domain_host" "$arg_new_domain_host"
				>&2 echo "domain updated"
			fi

			if [ -d "/var/www/html/web/app/cache" ]; then
				chown -R www-data:www-data "/var/www/html/web/app/cache"
			fi

			if [ -d "/var/www/html/web/app/w3tc-config" ]; then
				chown -R www-data:www-data "/var/www/html/web/app/w3tc-config"
			fi

			if [ -n "${arg_wp_rewrite_structure:-}" ]; then
				>&2 echo "rewrite structure to ${arg_wp_rewrite_structure:-}"
				wp --allow-root rewrite structure "${arg_wp_rewrite_structure:-}"
				>&2 echo "structure rewritten to ${arg_wp_rewrite_structure:-}"
			fi

			if [ "${arg_use_s3_storage:-}" = "true" ]; then
				>&2 echo "activate plugins: $s3_plugins"
				wp --allow-root plugin activate $s3_plugins
				>&2 echo "plugins activated: $s3_plugins"
			fi
		SHELL
		;;
	*)
		error "$command: invalid command"
		;;
esac
