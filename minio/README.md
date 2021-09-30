# Minio

This example deploys a pod with a Minio container that can be used as an S3-compatible service.

## Pod Parameters

TODO

## Deployment

There is a single type of deployment of this pod (at the moment):

- `app`: deploy all the containers in a single pod.

There are 2 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host.

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Minio service.

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/minio.yml.

The following deployments can be seen at https://github.com/lucasbasquerotto/env-base/tree/master/docs/pod/minio.

### Minimal Deployment - Local

```yaml
name: "minio-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/minio.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    minio: "localhost"
  pod_custom_dir_sync: true
  use_nginx: true
credentials:
  minio:
    access_key: "minio"
    secret_key: "minio123"
    access_key_old: "minio2"
    secret_key_old: "minio1232"
```

### Minimal Deployment - Remote

```yaml
name: "minio-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/minio.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    minio: "minio.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "minio"
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
  minio:
    access_key: "minio"
    secret_key: "minio123"
    access_key_old: "minio2"
    secret_key_old: "minio1232"
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
name: "minio-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/minio.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    minio: "localhost"
    private: "private.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
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
  minio_amount: 2
  minio_data_amount: 3
  minio_include_healthcheck: true
  minio_external_port: 9000
  use_pod_prefix: true
  use_secrets: false
  use_nginx: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_local_s3: true
  use_fluentd: true
  use_outer_proxy: false
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: false
  use_node_exporter: false
  use_pod_full_prefix: true
  define_s3_backup_lifecycle: true
  define_cron: true
  include_cron_watch: true
  enable_logs_backup: true
  enable_logs_setup: true
  enable_sync_backup: true
  enable_sync_setup: true
  enable_backup_replica: false
  local_standard_ports: false
  pod_custom_dir_sync: true
  inner_scripts_dir: ""
  named_volumes: false
  fluentd_output_plugin: "file"
  s3_cli: "awscli"
  outer_proxy_type: "cloudflare"
  auth_file: "demo/auth/.htpasswd"
  internal_ssl:
    fullchain: "demo/ssl/internal.bundle.crt"
    cert: "demo/ssl/internal.crt"
    ca: "demo/ssl/internal.ca.crt"
    privkey: "demo/ssl/internal.key"
  memory_app:
    nginx: 512mb
    minio: 512mb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  minio:
    access_key: "minio"
    secret_key: "minio123"
    access_key_old: "minio2"
    secret_key_old: "minio1232"
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "minio-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/minio.yml"
params:
  app_hostname: "minio_app"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    minio: "minio.{{ params.your_domain }}"
    private: "private-minio.{{ params.your_domain }}"
    theia: "files-minio.{{ params.your_domain }}"
    minio_gateway: "s3-minio.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "minio"
    - record: "private-minio"
    - record: "files-minio"
    - record: "s3-minio"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-2vcpu-2gb"
  certbot_email: "{{ params.certbot_email }}"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  db_setup_restore_remote_file: ""
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
  minio_amount: 2
  minio_data_amount: 3
  minio_include_healthcheck: true
  minio_external_port: 9000
  use_pod_prefix: true
  use_secrets: false
  use_nginx: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_local_s3: true
  use_fluentd: true
  use_outer_proxy: false
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: false
  use_node_exporter: false
  use_pod_full_prefix: true
  define_s3_backup_lifecycle: true
  define_cron: true
  include_cron_watch: true
  enable_logs_backup: true
  enable_logs_setup: true
  enable_sync_backup: true
  enable_sync_setup: true
  enable_backup_replica: false
  inner_scripts_dir: ""
  named_volumes: false
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
    nginx: 512mb
    minio: 512mb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  minio:
    access_key: "minio"
    secret_key: "minio123"
    access_key_old: "minio2"
    secret_key_old: "minio1232"
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
