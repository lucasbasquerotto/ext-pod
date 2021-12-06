# Base Pod

This is a basic example of a pod that has an Nginx service that returns a static response. To include the Nginx service the parameter `use_nginx` must be `true`, otherwise no relevant service will be running and the pod would be in its simplest form (there will be a `toolbox` container running, but there would be no service exposed externally).

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
name: "base-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/base.yml"
params:
  pod_custom_dir_sync: true
  use_nginx: true
```

### Minimal Deployment - Remote

```yaml
name: "base-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/base.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  dns_service_params_list:
    - record: "base"
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
name: "base-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/base.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    base: "localhost"
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
  use_pod_prefix: true
  use_secrets: true
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
  auth_file: "demo/auth/.htpasswd"
  internal_ssl:
    fullchain: "demo/ssl/internal.bundle.crt"
    cert: "demo/ssl/internal.crt"
    ca: "demo/ssl/internal.ca.crt"
    privkey: "demo/ssl/internal.key"
  memory_app:
    nginx: 512mb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "base-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/base.yml"
params:
  app_hostname: "base_app"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    base: "base.{{ params.your_domain }}"
    private: "private-base.{{ params.your_domain }}"
    theia: "files-base.{{ params.your_domain }}"
    minio_gateway: "s3-base.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "base"
    - record: "private-base"
    - record: "files-base"
    - record: "s3-base"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  certbot_email: "{{ params.certbot_email }}"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
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
  use_nginx: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
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
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
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
  s3:
    endpoint: "{{ params.s3_endpoint }}"
    access_key: "{{ params.s3_access_key }}"
    secret_key: "{{ params.s3_secret_key }}"
  minio_gateway:
    endpoint: "{{ params.minio_gateway_endpoint }}"
    access_key: "{{ params.minio_gateway_access_key }}"
    secret_key: "{{ params.minio_gateway_secret_key }}"
```

The above configuration expects some files to be defined in the project environment repository directory, that can be seen [here](#needed-environment-files).

# Needed Environment Files

Some configurations expect that certain files be generated and referenced beforehand. The path of these files must be relative to the project environment repository directory.

## Basic Authentication

By defining `use_basic_auth_private: true`, the private services expect basic authentication, whose file should be defined at:

- `demo/auth/.htpasswd`

*(To generate a basic authentication file with a user `user1`, run the command `htpasswd /path/to/.htpasswd user1`)*

## Internal SSL/TLS certificates

In certain cases, a service will expect a secure connection and there would need to be included TLS certificates to be used for communication between the pod services internally (and sometimes externally).

An example is that by defining `use_secure_elasticsearch: true`, the `fluentd` service in a pod will connect to `elasticsearch` using a secure connection (when `fluentd_output_plugin` is `elasticsearch`).

The certificates must be defined in the following files:

- `demo/ssl/internal.bundle.crt`
- `demo/ssl/internal.crt`
- `demo/ssl/internal.ca.crt`
- `demo/ssl/internal.key`

## SSH Connection

The SSH public and private files should be defined at, respectively:

- `demo/ssh/id_rsa.pub`
- `demo/ssh/id_rsa`

*(To generate the SSH files, run `ssh-keygen -t rsa`, then move the generated files to the `ssh` folder in the environment repository directory)*
