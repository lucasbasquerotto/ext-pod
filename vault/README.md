# Minio

This example deploys a pod with containers containing a Vault service.

## Pod Parameters

TODO

## Deployment

There is a single type of deployment of this pod (at the moment):

- `app`: deploy all the containers in a single pod.

There are 2 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host.

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Vault service.

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/vault.yml.

The following deployments can be seen at https://github.com/lucasbasquerotto/env-base/tree/master/docs/pod/vault.

### Minimal Deployment - Local

```yaml
name: "vault-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/vault.yml"
params:
  pod_custom_dir_sync: true
credentials:
  dev_vault:
    root_token: "vault123"
```

### Minimal Deployment - Remote

```yaml
name: "vault-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/vault.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    vault: "vault.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "vault"
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
name: "vault-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/vault.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    vault: "localhost"
    consul: "consul.localhost"
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
  dev_vault: true
  use_pod_prefix: true
  use_secrets: false
  use_nginx: true
  use_theia: true
  use_minio_gateway: true
  use_consul: true
  use_secure_consul: true
  use_s3: true
  use_local_s3: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: false
  use_node_exporter: false
  use_pod_full_prefix: true
  db_backup_use_s3: false
  define_cron: true
  include_cron_watch: true
  define_s3_backup_lifecycle: true
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
  auth_file: "demo/auth/.htpasswd"
  internal_ssl:
    fullchain: "demo/ssl/internal.bundle.crt"
    cert: "demo/ssl/internal.crt"
    ca: "demo/ssl/internal.ca.crt"
    privkey: "demo/ssl/internal.key"
  memory_app:
    nginx: 512mb
    vault: 1gb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  dev_vault:
    root_token: "vault123"
  consul:
    # consul keygen
    encrypt_key: "pUqJrVyVRj5jsiYEkM/tFQYfWyJIv4s3XkvDwy7Cu5s="
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "vault-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/vault.yml"
params:
  app_hostname: "vault_app"
  private_ips: "{{ params.private_ips | default([]) }}"
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  local_main_domain: "localhost"
  main_domain: "{{ params.your_domain }}"
  local_domains:
    vault: "localhost"
    consul: "consul.localhost"
    private: "private.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  domains:
    vault: "vault.{{ params.your_domain }}"
    private: "private-vault.{{ params.your_domain }}"
    consul: "consul-vault.{{ params.your_domain }}"
    theia: "files-vault.{{ params.your_domain }}"
    minio_gateway: "s3-vault.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "vault"
    - record: "private-vault"
    - record: "consul-vault"
    - record: "files-vault"
    - record: "s3-vault"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  certbot_email: "{{ params.certbot_email }}"
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
  run_nameserver_main: false
  run_dns_main: false
  dev_vault: false
  use_pod_prefix: true
  use_secrets: false
  use_nginx: true
  use_theia: true
  use_minio_gateway: true
  use_consul: true
  use_secure_consul: true
  use_s3: true
  use_local_s3: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: false
  use_node_exporter: false
  use_pod_full_prefix: true
  db_backup_use_s3: false
  define_cron: true
  include_cron_watch: true
  define_s3_backup_lifecycle: true
  enable_logs_backup: true
  enable_logs_setup: true
  enable_sync_backup: true
  enable_sync_setup: true
  enable_backup_replica: false
  local_standard_ports: false
  vault_external_port: "8200"
  inner_scripts_dir: ""
  named_volumes: false
  fluentd_output_plugin: "file"
  s3_cli: "awscli"
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
    vault: 1gb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  consul:
    # consul keygen
    encrypt_key: "pUqJrVyVRj5jsiYEkM/tFQYfWyJIv4s3XkvDwy7Cu5s="
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
