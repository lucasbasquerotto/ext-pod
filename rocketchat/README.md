# Rocketchat

This example deploys a pod with containers containing a Rocketchat service connected to a Mongo database.

## Pod Parameters

TODO

## Deployment

There are 3 types of deployment of this pod:

- `app`: deploy all the containers in a single pod.
- `db`: deploy the Mongo container.
- `web`: deploy the Rocketchat container.

There are 3 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host (the pod type is `app`).
- `nodes`: for remote deployments using 2 hosts: pod types `web` (nginx + rocketchat) and `db` (mongo).

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Rocketchat and Mongo services (with Nginx, optionally).

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/rocketchat.yml.

The following deployments can be seen at https://github.com/lucasbasquerotto/env-base/tree/master/docs/pod/rocketchat.

### Minimal Deployment - Local

```yaml
name: "rocketchat-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/rocketchat.yml"
params:
  pod_custom_dir_sync: true
credentials:
  rocketchat_db:
    name: "rocketchat"
    user: "rocket"
    password: "111111"
    root_user: "root"
    root_password: "222222"
    viewer_password: "333333"
    oploguser_password: "444444"
```

### Minimal Deployment - Remote

```yaml
name: "rocketchat-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/rocketchat.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  dns_service_params_list:
    - record: "rocketchat"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  meta:
    ignore_validators: false
    skip_local_node_preparation: false
    skip_local_pod_preparation: false
    template_no_empty_lines: true
  host_ssh_public_keys_content:
    origin: "env"
    file: "demo/ssh/id_rsa.pub"
credentials:
  rocketchat_db:
    name: "rocketchat"
    user: "rocket"
    password: "111111"
    root_user: "root"
    root_password: "222222"
    viewer_password: "333333"
    oploguser_password: "444444"
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
name: "rocketchat-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/rocketchat.yml"
params:
  rocketchat_smtp_from: "contact@chat.example.com"
  local_main_domain: "localhost"
  local_domains:
    rocketchat: "localhost"
    private: "private.localhost"
    mongo_express: "me.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/rocketchat/db/20200612_221938.zip?raw=true"
  uploads_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/rocketchat/uploads/20200612_221938.zip?raw=true"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  uploads_bucket_name: "{{ params.uploads_bucket_name }}"
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
  use_rocketchat_mail: true
  non_s3_setup: true
  use_nginx: true
  use_mongo_express: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_local_s3: true
  use_s3_storage: false
  use_fluentd: true
  use_outer_proxy: false
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: false
  use_node_exporter: false
  use_pod_full_prefix: true
  use_bot: true
  db_gui_root_user: true
  block_ips: true
  s3_uploads: false
  define_cron: true
  include_cron_watch: true
  define_s3_backup_lifecycle: true
  enable_db_backup: true
  enable_db_setup: true
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
  local_uploads_backup_sync: true
  rocketchat_block_default_settings: true
  pod_custom_dir_sync: true
  inner_scripts_dir: ""
  named_volumes: false
  fluentd_output_plugin: "file"
  s3_cli: "mc"
  auth_file: "demo/auth/.htpasswd"
  memory_app:
    nginx: 512mb
    rocketchat: 1gb
    hubot: 512mb
    mongo_express: 512mb
    mongo: 1gb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    mongo_init: 512mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  rocketchat_db:
    name: "rocketchat"
    user: "rocket"
    password: "111111"
    root_user: "root"
    root_password: "222222"
    viewer_password: "333333"
    oploguser_password: "444444"
  rocketchat_mail:
    address: "smtp.sendgrid.net"
    port: "587"
    ignore_tls: false
    smtp_username: "apikey"
    smtp_password: "{{ params.sendgrid_password }}"
  hubot:
    email: "hubot@test.internal"
    room: ""
    user: "mybot"
    password: "mypass"
    bot_name: "bothere"
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "rocketchat-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/rocketchat.yml"
params:
  app_hostname: "rocketchat_app"
  db_hostname: "rocketchat_db"
  web_hostname: "rocketchat_web"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  rocketchat_smtp_from: "contact@chat.{{ params.your_domain }}"
  main_domain: "{{ params.your_domain }}"
  domains:
    rocketchat: "chat.{{ params.your_domain }}"
    private: "private-chat.{{ params.your_domain }}"
    mongo_express: "me-chat.{{ params.your_domain }}"
    theia: "files-chat.{{ params.your_domain }}"
    minio_gateway: "s3-chat.{{ params.your_domain }}"
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/rocketchat/db/20200612_221938.zip?raw=true"
  uploads_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/rocketchat/uploads/20200612_221938.zip?raw=true"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-2vcpu-2gb"
  certbot_email: "{{ params.certbot_email }}"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  uploads_bucket_name: "{{ params.uploads_bucket_name }}"
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
  use_rocketchat_mail: true
  non_s3_setup: true
  use_nginx: true
  use_mongo_express: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_s3_storage: false
  use_fluentd: true
  use_outer_proxy: false
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: false
  use_node_exporter: false
  use_pod_full_prefix: true
  use_bot: true
  db_gui_root_user: true
  block_ips: true
  s3_uploads: false
  define_cron: true
  include_cron_watch: true
  define_s3_backup_lifecycle: true
  enable_db_backup: true
  enable_db_setup: true
  enable_logs_backup: true
  enable_logs_setup: true
  enable_sync_backup: true
  enable_sync_setup: true
  enable_uploads_backup: true
  enable_uploads_setup: true
  enable_backup_replica: false
  enable_uploads_replica: false
  rocketchat_block_default_settings: true
  inner_scripts_dir: ""
  named_volumes: false
  fluentd_output_plugin: "file"
  s3_cli: "mc"
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
    nginx: 512mb
    rocketchat: 1gb
    hubot: 512mb
    mongo_express: 512mb
    mongo: 1gb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    mongo_init: 512mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  rocketchat_db:
    name: "rocketchat"
    user: "rocket"
    password: "111111"
    root_user: "root"
    root_password: "222222"
    viewer_password: "333333"
    oploguser_password: "444444"
  rocketchat_mail:
    address: "smtp.sendgrid.net"
    port: "587"
    ignore_tls: false
    smtp_username: "apikey"
    smtp_password: "{{ params.sendgrid_password }}"
  hubot:
    email: "hubot@test.internal"
    room: ""
    user: "mybot"
    password: "mypass"
    bot_name: "bothere"
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
