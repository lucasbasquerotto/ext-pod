# Wordpress

This example deploys a pod with containers containing a Wordpress service connected to a MySQL database.

## Pod Parameters

TODO

## Deployment

There are 3 types of deployment of this pod:

- `app`: deploy all the containers in a single pod.
- `db`: deploy the MySQL container.
- `web`: deploy the Wordpress container.

There are 3 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host (the pod type is `app`).
- `nodes`: for remote deployments using 2 hosts: pod types `web` (nginx + wordpress) and `db` (mysql).

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Wordpress and MySQL services (with Nginx, optionally).

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/wordpress.yml.

The following deployments can be seen at https://github.com/lucasbasquerotto/env-base/tree/master/docs/pod/wordpress.

### Minimal Deployment - Local

```yaml
name: "wordpress-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/wordpress.yml"
params:
  pod_custom_dir_sync: true
  app_dev: false
  enable_db_setup_new: true
credentials:
  mysql:
    root_password: "111111"
    viewer_password: "222222"
  wordpress:
    db:
      name: "wordpress"
      user: "wp_user"
      password: "123456"
    setup:
      admin_user: "wp_user"
      admin_password: "111222"
      admin_email: "email@domain.com"
    config:
      auth_key: ")}rFg|03au>%G;xa<nBi+Nk@9o2A>X[*W]W]oymh#)-=AYIIoAD]i6OmfLWD)#P6"
      secure_auth_key: "Xu+V0E/)y|i?5*l?8LLV/;HE{?xa)~m[~SS0D5d uDabtwqNu-:T2lP=J]s<J<oG"
      logged_in_key: "sCaHS-}0)n8+2Ow^l}IDyjHLx#ym*%#po`8h|7JIv#~j4w}*q%nDl-7<vjF([ltT"
      nonce_key: ")^q3T5{ 2/u|M+>[kbPq(_<y/(7Y,0`TQ>y|b+40MT?AQ~B6mM-SOnh;@~%[Hy3J"
      auth_salt: "Y|b[TK:~|=&Xxl*!0Jm3{H!N~?_<- ADG5dxmdM{ETs|`5|,fKa{+m=7fuoy:8c|"
      secure_auth_salt: "+ekE BMikKj-;iSsIgVhDG*OAPss!XZ[Rb$_0i)]h94vtX%1)<5BwOjjj1C3_$uZ"
      logged_in_salt: "9iO)S9xRz aI:c4tOo,Z`(!)7lO[I|!S)r<hP9fK-9hP:n/;))T=Z8Z-p-xNI[$F"
      nonce_salt: "4r<DkL7|vgmtZ)]9=%TaQT8Dw#p;YAE9.G-o;Z7rbtRrKlF9w0ykmtUBZ?-~n(9q"
```

### Minimal Deployment - Remote

```yaml
name: "wordpress-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/wordpress.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    wordpress: "blog.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "blog"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  meta:
    ignore_validators: false
    skip_local_node_preparation: false
    skip_local_pod_preparation: false
    template_no_empty_lines: true
  app_dev: false
  enable_db_setup_new: true
  use_nginx: true
  host_ssh_public_keys_content:
    origin: "env"
    file: "demo/ssh/id_rsa.pub"
credentials:
  mysql:
    root_password: "111111"
    viewer_password: "222222"
  wordpress:
    db:
      name: "wordpress"
      user: "wp_user"
      password: "123456"
    setup:
      admin_user: "wp_user"
      admin_password: "111222"
      admin_email: "email@domain.com"
    config:
      auth_key: ")}rFg|03au>%G;xa<nBi+Nk@9o2A>X[*W]W]oymh#)-=AYIIoAD]i6OmfLWD)#P6"
      secure_auth_key: "Xu+V0E/)y|i?5*l?8LLV/;HE{?xa)~m[~SS0D5d uDabtwqNu-:T2lP=J]s<J<oG"
      logged_in_key: "sCaHS-}0)n8+2Ow^l}IDyjHLx#ym*%#po`8h|7JIv#~j4w}*q%nDl-7<vjF([ltT"
      nonce_key: ")^q3T5{ 2/u|M+>[kbPq(_<y/(7Y,0`TQ>y|b+40MT?AQ~B6mM-SOnh;@~%[Hy3J"
      auth_salt: "Y|b[TK:~|=&Xxl*!0Jm3{H!N~?_<- ADG5dxmdM{ETs|`5|,fKa{+m=7fuoy:8c|"
      secure_auth_salt: "+ekE BMikKj-;iSsIgVhDG*OAPss!XZ[Rb$_0i)]h94vtX%1)<5BwOjjj1C3_$uZ"
      logged_in_salt: "9iO)S9xRz aI:c4tOo,Z`(!)7lO[I|!S)r<hP9fK-9hP:n/;))T=Z8Z-p-xNI[$F"
      nonce_salt: "4r<DkL7|vgmtZ)]9=%TaQT8Dw#p;YAE9.G-o;Z7rbtRrKlF9w0ykmtUBZ?-~n(9q"
  host:
    host_user: "host"
    host_pass: "111222"
    ssh_file: "demo/ssh/id_rsa"
  digital_ocean:
    api_token: "{{ params.digital_ocean_api_token }}"
  cloudflare:
    email: "{{ params.cloudflare_email }}"
    token: "{{ params.cloudflare_token }}"
```

### Complete Deployment - Local

```yaml
name: "wordpress-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/wordpress.yml"
params:
  local_main_domain: "localhost"
  wordpress_smtp_from: "contact@localhost"
  wordpress_smtp_name: "My Test Blog"
  local_domains:
    wordpress: "localhost"
    private: "private.localhost"
    phpmyadmin: "pma.localhost"
    adminer: "adminer.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/wordpress/db/20210901_155233.zip?raw=true"
  uploads_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/wordpress/uploads/20210901_155302.zip?raw=true"
  wp_title: "My Blog Title"
  backup_bucket_name: "wp-backup"
  uploads_bucket_name: "wp-uploads"
  migrate_wp_plugins_to_activate: ["contact-form-7"]
  migrate_wp_plugins_to_deactivate:
    ["ewww-image-optimizer", "jetpack", "wp-mail-smtp", "wpdiscuz"]
  meta:
    ignore_validators: true
    skip_local_node_preparation: true
    skip_local_pod_preparation: true
    template_no_empty_lines: true
  pod_meta:
    no_stacktrace: false
    no_info: false
    no_info_wrap: false
    no_summary: false
    no_colors: false
  use_pod_prefix: true
  use_secrets: true
  use_wordpress_mail: true
  use_nginx: true
  use_varnish: true
  use_redis: false
  use_memcached: false
  use_composer: true
  use_pma: true
  use_adminer: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_local_s3: true
  use_s3_storage: false
  use_custom_mail_plugin: true
  use_fluentd: true
  use_w3tc: true
  use_outer_proxy: false
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_node_exporter: false
  use_pod_full_prefix: true
  non_s3_setup: true
  wp_debug: true
  db_gui_root_user: true
  block_ips: true
  define_s3_backup_lifecycle: true
  define_cron: true
  include_cron_watch: true
  enable_db_backup: true
  enable_db_setup: true
  enable_db_setup_new: false
  enable_logs_backup: true
  enable_logs_setup: true
  enable_sync_backup: true
  enable_sync_setup: true
  enable_uploads_backup: true
  enable_uploads_setup: true
  enable_backup_replica: false
  enable_uploads_replica: false
  local_standard_ports: false
  local_db_backup_sync: false
  local_uploads_backup_sync: false
  pod_custom_dir_sync: true
  inner_scripts_dir: ""
  named_volumes: false
  app_dev: false
  fluentd_output_plugin: "file"
  s3_cli: "awscli"
  outer_proxy_type: "cloudflare"
  auth_file: "demo/auth/.htpasswd"
  memory_app:
    nginx: 256mb
    varnish: 256mb
    wordpress: 512mb
    redis: 256mb
    memcached: 256mb
    pma: 256mb
    adminer: 256mb
    mysql: 512mb
    theia: 512mb
    minio_gateway: 256mb
    toolbox: 256mb
    composer: 256mb
    fluentd: 256mb
    certbot: 256mb
    s3_cli: 256mb
credentials:
  mysql:
    root_password: "111111"
    viewer_password: "222222"
  wordpress:
    db:
      name: "wordpress"
      user: "wp_user"
      password: "123456"
    setup:
      admin_user: "wp_user"
      admin_password: "111222"
      admin_email: "email@domain.com"
    config:
      auth_key: ")}rFg|03au>%G;xa<nBi+Nk@9o2A>X[*W]W]oymh#)-=AYIIoAD]i6OmfLWD)#P6"
      secure_auth_key: "Xu+V0E/)y|i?5*l?8LLV/;HE{?xa)~m[~SS0D5d uDabtwqNu-:T2lP=J]s<J<oG"
      logged_in_key: "sCaHS-}0)n8+2Ow^l}IDyjHLx#ym*%#po`8h|7JIv#~j4w}*q%nDl-7<vjF([ltT"
      nonce_key: ")^q3T5{ 2/u|M+>[kbPq(_<y/(7Y,0`TQ>y|b+40MT?AQ~B6mM-SOnh;@~%[Hy3J"
      auth_salt: "Y|b[TK:~|=&Xxl*!0Jm3{H!N~?_<- ADG5dxmdM{ETs|`5|,fKa{+m=7fuoy:8c|"
      secure_auth_salt: "+ekE BMikKj-;iSsIgVhDG*OAPss!XZ[Rb$_0i)]h94vtX%1)<5BwOjjj1C3_$uZ"
      logged_in_salt: "9iO)S9xRz aI:c4tOo,Z`(!)7lO[I|!S)r<hP9fK-9hP:n/;))T=Z8Z-p-xNI[$F"
      nonce_salt: "4r<DkL7|vgmtZ)]9=%TaQT8Dw#p;YAE9.G-o;Z7rbtRrKlF9w0ykmtUBZ?-~n(9q"
  wordpress_mail:
    address: "smtp.sendgrid.net"
    port: "587"
    secure: "tls"
    smtp_username: "apikey"
    smtp_password: "{{ params.sendgrid_password }}"
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "wordpress-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/wordpress.yml"
params:
  app_hostname: "wordpress_app"
  db_hostname: "wordpress_db"
  cache_hostname: "wordpress_cache"
  web_hostname: "wordpress_web"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  wordpress_smtp_from: "contact@blog.{{ params.your_domain }}"
  wordpress_smtp_name: "My Test Blog"
  domains:
    wordpress: "blog.{{ params.your_domain }}"
    private: "private-blog.{{ params.your_domain }}"
    phpmyadmin: "pma-blog.{{ params.your_domain }}"
    adminer: "adminer-blog.{{ params.your_domain }}"
    theia: "files-blog.{{ params.your_domain }}"
    minio_gateway: "s3-blog.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "blog"
    - record: "private-blog"
    - record: "pma-blog"
    - record: "adminer-blog"
    - record: "files-blog"
    - record: "s3-blog"
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/wordpress/db/20210901_155233.zip?raw=true"
  uploads_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/wordpress/uploads/20210901_155302.zip?raw=true"
  wp_remote_seed_data: "https://gist.githubusercontent.com/lucasbasquerotto/667447640482369d0c6b093ee7200c96/raw/9d9d446b9f1017aa4bc12628aea954f1f10f020c/wordpress-theme-unit-test-data.xml"
  wp_old_domain_host: "http://localhost:8080/"
  wp_new_domain_host: "http://blog.{{ params.your_domain }}/"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-2vcpu-2gb"
  certbot_email: "{{ params.certbot_email }}"
  wp_title: "My Blog Title"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  uploads_bucket_name: "{{ params.uploads_bucket_name }}"
  migrate_wp_plugins_to_activate: ["contact-form-7"]
  migrate_wp_plugins_to_deactivate:
    ["ewww-image-optimizer", "jetpack", "wp-mail-smtp", "wpdiscuz"]
  meta:
    ignore_validators: false
    skip_local_node_preparation: false
    skip_local_pod_preparation: false
    template_no_empty_lines: true
  pod_meta:
    no_stacktrace: false
    no_info: false
    no_info_wrap: false
    no_summary: false
    no_colors: false
  run_nameserver_main: false
  run_dns_main: false
  use_pod_prefix: true
  use_secrets: true
  use_wordpress_mail: true
  use_nginx: true
  use_varnish: true
  use_redis: false
  use_memcached: false
  use_composer: true
  use_pma: true
  use_adminer: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_s3_storage: false
  use_custom_mail_plugin: true
  use_fluentd: true
  use_w3tc: true
  use_outer_proxy: false
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_node_exporter: false
  use_pod_full_prefix: true
  non_s3_setup: true
  wp_debug: true
  db_gui_root_user: true
  block_ips: true
  define_s3_backup_lifecycle: true
  define_cron: true
  include_cron_watch: true
  enable_db_backup: true
  enable_db_setup: true
  enable_db_setup_new: false
  enable_logs_backup: true
  enable_logs_setup: true
  enable_sync_backup: true
  enable_sync_setup: true
  enable_uploads_backup: true
  enable_uploads_setup: true
  enable_backup_replica: false
  enable_uploads_replica: false
  inner_scripts_dir: ""
  named_volumes: false
  app_dev: false
  fluentd_output_plugin: "file"
  s3_cli: "awscli"
  outer_proxy_type: "cloudflare"
  auth_file: "demo/auth/.htpasswd"
  internal_ssl:
    fullchain: "demo/ssl/internal.bundle.crt"
    cert: "demo/ssl/internal.crt"
    ca: "demo/ssl/internal.ca.crt"
    privkey: "demo/ssl/internal.key"
  host_ssh_public_keys_content:
    origin: "env"
    file: "demo/ssh/id_rsa.pub"
  memory_app:
    nginx: 256mb
    varnish: 256mb
    wordpress: 512mb
    redis: 256mb
    memcached: 256mb
    pma: 256mb
    adminer: 256mb
    mysql: 512mb
    theia: 512mb
    minio_gateway: 256mb
    toolbox: 256mb
    composer: 256mb
    fluentd: 256mb
    certbot: 256mb
    s3_cli: 256mb
credentials:
  mysql:
    root_password: "111111"
    viewer_password: "222222"
  wordpress:
    db:
      name: "wordpress"
      user: "wp_user"
      password: "123456"
    setup:
      admin_user: "wp_user"
      admin_password: "111222"
      admin_email: "email@domain.com"
    config:
      auth_key: ")}rFg|03au>%G;xa<nBi+Nk@9o2A>X[*W]W]oymh#)-=AYIIoAD]i6OmfLWD)#P6"
      secure_auth_key: "Xu+V0E/)y|i?5*l?8LLV/;HE{?xa)~m[~SS0D5d uDabtwqNu-:T2lP=J]s<J<oG"
      logged_in_key: "sCaHS-}0)n8+2Ow^l}IDyjHLx#ym*%#po`8h|7JIv#~j4w}*q%nDl-7<vjF([ltT"
      nonce_key: ")^q3T5{ 2/u|M+>[kbPq(_<y/(7Y,0`TQ>y|b+40MT?AQ~B6mM-SOnh;@~%[Hy3J"
      auth_salt: "Y|b[TK:~|=&Xxl*!0Jm3{H!N~?_<- ADG5dxmdM{ETs|`5|,fKa{+m=7fuoy:8c|"
      secure_auth_salt: "+ekE BMikKj-;iSsIgVhDG*OAPss!XZ[Rb$_0i)]h94vtX%1)<5BwOjjj1C3_$uZ"
      logged_in_salt: "9iO)S9xRz aI:c4tOo,Z`(!)7lO[I|!S)r<hP9fK-9hP:n/;))T=Z8Z-p-xNI[$F"
      nonce_salt: "4r<DkL7|vgmtZ)]9=%TaQT8Dw#p;YAE9.G-o;Z7rbtRrKlF9w0ykmtUBZ?-~n(9q"
  wordpress_mail:
    address: "smtp.sendgrid.net"
    port: "587"
    secure: "tls"
    smtp_username: "apikey"
    smtp_password: "{{ params.sendgrid_password }}"
  host:
    host_user: "host"
    host_pass: "111222"
    ssh_file: "demo/ssh/id_rsa"
  digital_ocean:
    api_token: "{{ params.digital_ocean_api_token }}"
  cloudflare:
    email: "{{ params.cloudflare_email }}"
    token: "{{ params.cloudflare_token }}"
  s3:
    endpoint: "{{ params.s3_endpoint }}"
    access_key: "{{ params.s3_access_key }}"
    secret_key: "{{ params.s3_secret_key }}"
  minio_gateway:
    endpoint: "{{ params.minio_gateway_endpoint }}"
    access_key: "{{ params.minio_gateway_access_key }}"
    secret_key: "{{ params.minio_gateway_secret_key }}"
```

The above configuration expects some files to be defined in the environment repository directory, that can be seen [here](../base/README.md#needed-environment-files).
