# Ghost

This example deploys a pod with containers containing a Ghost service connected to a MySQL database.

## Pod Parameters

TODO

## Deployment

There are 3 types of deployment of this pod:

- `app`: deploy all the containers in a single pod.
- `db`: deploy the MySQL container.
- `web`: deploy the Ghost container.

There are 3 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host (the pod type is `app`).
- `nodes`: for remote deployments using 2 hosts: pod types `web` (nginx + ghost) and `db` (mysql).

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Ghost and MySQL services (with Nginx, optionally).

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/ghost.yml.

The following deployments can be seen at https://github.com/lucasbasquerotto/env-base/tree/master/docs/pod/ghost.

### Minimal Deployment - Local

```yaml
name: "ghost-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/ghost.yml"
params:
  pod_custom_dir_sync: true
  use_nginx: true
credentials:
  db:
    root_password: "111111"
    viewer_password: "222222"
    name: "ghost_db"
    user: "ghost_user"
    password: "333333"
  ghost_mail: {}
```

### Minimal Deployment - Remote

```yaml
name: "ghost-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/ghost.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    ghost: "blog.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "blog"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  meta:
    ignore_validators: false
    skip_local_node_preparation: false
    skip_local_pod_preparation: false
    template_no_empty_lines: true
  use_nginx: true
  host_ssh_public_keys_content:
    origin: "env"
    file: "demo/ssh/id_rsa.pub"
credentials:
  db:
    root_password: "111111"
    viewer_password: "222222"
    name: "ghost_db"
    user: "ghost_user"
    password: "333333"
  ghost_mail: {}
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
name: "ghost-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/ghost.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    ghost: "localhost"
    private: "private.localhost"
    phpmyadmin: "pma.localhost"
    adminer: "adminer.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  uploads_bucket_name: "{{ params.uploads_bucket_name }}"
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/ghost/db/20210505_013103.zip?raw=true"
  uploads_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/ghost/uploads/20210505_013115.zip?raw=true"
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
  use_varnish: true
  use_pma: true
  use_adminer: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_pod_full_prefix: true
  define_s3_backup_lifecycle: true
  non_s3_setup: true
  db_gui_root_user: true
  block_ips: true
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
    varnish: 512mb
    ghost: 1gb
    pma: 512mb
    adminer: 512mb
    mysql: 1gb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  db:
    root_password: "111111"
    viewer_password: "222222"
    name: "ghost_db"
    user: "ghost_user"
    password: "333333"
  ghost_mail:
    from: "'My Send Email' <{{ params.sender_email }}>"
    transport: "SMTP"
    options:
      service: "Sendgrid"
      host: "smtp.sendgrid.net"
      port: "587"
      auth:
        user: "apikey"
        pass: "{{ params.sendgrid_password }}"
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "ghost-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/ghost.yml"
params:
  app_hostname: "ghost_app"
  db_hostname: "ghost_db"
  web_hostname: "ghost_web"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    ghost: "blog.{{ params.your_domain }}"
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
  run_dns_main: false
  use_pod_prefix: true
  use_secrets: false
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_nginx: true
  use_varnish: true
  use_pma: true
  use_adminer: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_node_exporter: false
  use_pod_full_prefix: true
  define_s3_backup_lifecycle: true
  non_s3_setup: true
  db_gui_root_user: true
  block_ips: true
  define_cron: true
  include_cron_watch: true
  enable_db_backup: true
  enable_db_setup: false
  enable_logs_backup: true
  enable_logs_setup: false
  enable_sync_backup: true
  enable_sync_setup: false
  enable_backup_replica: false
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
    varnish: 512mb
    ghost: 1gb
    pma: 512mb
    adminer: 512mb
    mysql: 1gb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  db:
    root_password: "111111"
    viewer_password: "222222"
    name: "ghost_db"
    user: "ghost_user"
    password: "333333"
  ghost_mail:
    from: "'My Send Email' <{{ params.sender_email }}>"
    transport: "SMTP"
    options:
      service: "Sendgrid"
      host: "smtp.sendgrid.net"
      port: "587"
      auth:
        user: "apikey"
        pass: "{{ params.sendgrid_password }}"
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

The above configuration expects some files to be defined in the project environment repository directory, that can be seen [here](../base/README.md#needed-environment-files).
