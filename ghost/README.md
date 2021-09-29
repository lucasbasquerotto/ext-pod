# Ghost

This example deploys a pod with containers containing a Ghost service connected to a MySQL database.

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

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/ghost.yml

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
  private_ips: ["<< private_ip >>"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "<< your_domain >>"
  domains:
    ghost: "blog.<< your_domain >>"
  dns_service_params_list:
    - record: "blog"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  meta:
    template_no_empty_lines: true
  use_nginx: true
  host_ssh_public_keys_content:
    origin: "env"
    file: "ssh/id_rsa.pub"
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
    ssh_file: "ssh/id_rsa"
  digital_ocean:
    api_token: "<< digital_ocean_api_token >>"
  cloudflare:
    email: "<< cloudflare_email >>"
    token: "<< cloudflare_token >>"
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
    kibana: "localhost"
    private: "private.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  backup_bucket_name: "ghost-backup"
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
  auth_file: "auth/.htpasswd"
  fluentd_output_plugin: "elasticsearch"
  local_custom_ssl:
    fullchain: "ssl/internal.bundle.crt"
    cert: "ssl/internal.crt"
    ca: "ssl/internal.ca.crt"
    privkey: "ssl/internal.key"
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
    from: "'My Send Email' <me@domain.com>"
    transport: "SMTP"
    options:
      service: "Sendgrid"
      host: "smtp.sendgrid.net"
      port: "587"
      auth:
        user: "apikey"
        pass: "<< sendgrid_pass >>"
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
  private_ips: ["<< private_ip >>"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "<< your_domain >>"
  domains:
    ghost: "blog.<< your_domain >>"
    private: "private-blog.<< your_domain >>"
    theia: "files-blog.<< your_domain >>"
    minio_gateway: "s3-blog.<< your_domain >>"
  dns_service_params_list:
    - record: "blog"
    - record: "private-blog"
    - record: "files-blog"
    - record: "s3-blog"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-2vcpu-2gb"
  certbot_email: "<< certbot_email >>"
  backup_bucket_name: "<< backup_bucket_name >>"
  meta:
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
  auth_file: "auth/.htpasswd"
  expose_elasticsearch_port: true
  elasticsearch_external_port: "9200"
  fluentd_output_plugin: "elasticsearch"
  internal_ssl:
    fullchain: "ssl/internal.bundle.crt"
    cert: "ssl/internal.crt"
    ca: "ssl/internal.ca.crt"
    privkey: "ssl/internal.key"
  host_ssh_public_keys_content:
    origin: "env"
    file: "ssh/id_rsa.pub"
  memory_app:
    nginx: 512mb
    kibana: 512mb
    elasticsearch: 1512mb
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
    from: "'My Send Email' <me@domain.com>"
    transport: "SMTP"
    options:
      service: "Sendgrid"
      host: "smtp.sendgrid.net"
      port: "587"
      auth:
        user: "apikey"
        pass: "<< sendgrid_pass >>"
  host:
    host_user: "host"
    host_pass: "111222"
    ssh_file: "ssh/id_rsa"
  digital_ocean:
    api_token: "<< digital_ocean_api_token >>"
  s3:
    endpoint: "<< s3_endpoint >>"
    access_key: "<< s3_access_key >>"
    secret_key: "<< s3_secret_key >>"
  minio_gateway:
    endpoint: "<< minio_gateway_replica_endpoint >>"
    access_key: "<< minio_gateway_replica_access_key >>"
    secret_key: "<< minio_gateway_replica_secret_key >>"
  cloudflare:
    email: "<< cloudflare_email >>"
    token: "<< cloudflare_token >>"
```

The above configuration expects some files to be defined in the environment repository directory, that can be seen [here](../base/README.md#needed-environment-files).

## Pod Parameters

TODO