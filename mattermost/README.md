# Mattermost

This example deploys a pod with containers containing a Mattermost service connected to a Postgres database.

## Pod Parameters

TODO

## Deployment

There are 3 types of deployment of this pod:

- `app`: deploy all the containers in a single pod.
- `db`: deploy the Postgres container.
- `web`: deploy the Mattermost container.

There are 3 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host (the pod type is `app`).
- `nodes`: for remote deployments using 2 hosts: pod types `web` (nginx + mattermost) and `db` (postgres).

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Mattermost and Postgres services (with Nginx, optionally).

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/mattermost.yml

### Minimal Deployment - Local

```yaml
name: "mattermost-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/mattermost.yml"
params:
  pod_custom_dir_sync: true
  use_nginx: true
credentials:
  postgres:
    root_password: "111111"
    viewer_password: "222222"
    db_name: "mmdb"
    db_user: "mattermost"
    db_password: "333333"
```

### Minimal Deployment - Remote

```yaml
name: "mattermost-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/mattermost.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    mattermost: "chat.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "chat"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  meta:
    template_no_empty_lines: true
  use_nginx: true
  host_ssh_public_keys_content:
    origin: "env"
    file: "demo/ssh/id_rsa.pub"
credentials:
  postgres:
    root_password: "111111"
    viewer_password: "222222"
    db_name: "mmdb"
    db_user: "mattermost"
    db_password: "333333"
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
name: "mattermost-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/mattermost.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    kibana: "localhost"
    private: "private.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  backup_bucket_name: "mattermost-backup"
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/mattermost/db/20210608_002440.zip?raw=true"
  uploads_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/mattermost/uploads/20210608_002449.zip?raw=true"
  meta:
    ignore_validators: true
    skip_local_node_preparation: true
    skip_local_pod_preparation: true
    template_no_empty_lines: true
  use_pod_prefix: true
  use_secrets: false
  use_kibana: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_local_s3: true
  use_nginx: true
  use_pgadmin: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_pod_full_prefix: true
  db_backup_s3_snapshot: true
  define_s3_backup_lifecycle: true
  define_cron: true
  include_cron_watch: true
  enable_db_backup: true
  enable_db_setup: true
  enable_logs_backup: true
  enable_logs_setup: true
  enable_sync_backup: true
  enable_sync_setup: true
  enable_backup_replica: false
  local_standard_ports: false
  pod_custom_dir_sync: true
  inner_scripts_dir: ""
  named_volumes: false
  s3_cli: "awscli"
  auth_file: "demo/auth/.htpasswd"
  fluentd_output_plugin: "file"
  local_custom_ssl:
    fullchain: "demo/ssl/internal.bundle.crt"
    cert: "demo/ssl/internal.crt"
    ca: "demo/ssl/internal.ca.crt"
    privkey: "demo/ssl/internal.key"
  memory_app:
    nginx: 512mb
    mattermost: 1gb
    pgadmin: 512mb
    adminer: 512mb
    postgres: 1gb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  postgres:
    root_password: "111111"
    viewer_password: "222222"
    db_name: "mmdb"
    db_user: "mattermost"
    db_password: "333333"
  mattermost:
    secret_key: "abce374745180efeeb2202933493d132429e589d59209f43f8325d59c7d4ebba"
  mattermost_mail:
    address: "smtp.sendgrid.net"
    port: "587"
    connection_security: "STARTTLS"
    smtp_username: "apikey"
    smtp_password: "{{ params.sendgrid_password }}"
  pgadmin:
    email: "{{ params.your_email }}"
    password: "123456"
```

### Complete Deployment - Remote

```yaml
name: "mattermost-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/mattermost.yml"
params:
  app_hostname: "mattermost_app"
  db_hostname: "mattermost_db"
  web_hostname: "mattermost_web"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    mattermost: "chat.{{ params.your_domain }}"
    private: "private-chat.{{ params.your_domain }}"
    theia: "files-chat.{{ params.your_domain }}"
    minio_gateway: "s3-chat.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "chat"
    - record: "private-chat"
    - record: "files-chat"
    - record: "s3-chat"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-2vcpu-2gb"
  certbot_email: "{{ params.certbot_email }}"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  meta:
    template_no_empty_lines: true
  run_dns_main: false
  use_pod_prefix: true
  use_secrets: false
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_nginx: true
  use_pgadmin: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_node_exporter: false
  use_pod_full_prefix: true
  db_backup_s3_snapshot: true
  define_s3_backup_lifecycle: true
  define_cron: true
  include_cron_watch: true
  enable_db_backup: true
  enable_db_setup: false
  enable_logs_backup: true
  enable_logs_setup: false
  enable_sync_backup: true
  enable_sync_setup: false
  enable_backup_replica: false
  pod_custom_dir_sync: true
  inner_scripts_dir: ""
  named_volumes: false
  s3_cli: "awscli"
  auth_file: "demo/auth/.htpasswd"
  fluentd_output_plugin: "file"
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
    kibana: 512mb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  postgres:
    root_password: "111111"
    viewer_password: "222222"
    db_name: "mmdb"
    db_user: "mattermost"
    db_password: "333333"
  mattermost:
    secret_key: "abce374745180efeeb2202933493d132429e589d59209f43f8325d59c7d4ebba"
  mattermost_mail:
    address: "smtp.sendgrid.net"
    port: "587"
    connection_security: "STARTTLS"
    smtp_username: "apikey"
    smtp_password: "{{ params.sendgrid_password }}"
  pgadmin:
    email: "{{ params.your_email }}"
    password: "123456"
  host:
    host_user: "host"
    host_pass: "111222"
    ssh_file: "demo/ssh/id_rsa"
  digital_ocean:
    api_token: "{{ params.digital_ocean_api_token }}"
  s3:
    endpoint: "{{ params.s3_endpoint }}"
    access_key: "{{ params.s3_access_key }}"
    secret_key: "{{ params.s3_secret_key }}"
  minio_gateway:
    endpoint: "{{ params.minio_gateway_endpoint }}"
    access_key: "{{ params.minio_gateway_access_key }}"
    secret_key: "{{ params.minio_gateway_secret_key }}"
  cloudflare:
    email: "{{ params.cloudflare_email }}"
    token: "{{ params.cloudflare_token }}"
```

The above configuration expects some files to be defined in the environment repository directory, that can be seen [here](../base/README.md#needed-environment-files).
