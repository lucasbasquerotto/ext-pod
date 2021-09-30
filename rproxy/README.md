# Reverse Proxy

This example deploys a pod with containers containing a reverse proxy (Nginx or HAProxy) service.

## Pod Parameters

TODO

## Deployment

There is a single type of deployment of this pod (at the moment):

- `app`: deploy all the containers in a single pod.

There are 7 main cloud contexts that can be used (in the project environment base file used as an example, but you can create your own environment file that does things differently):

- `local`: for local deployment.
- `local_hub`: for local deployment with several pods accessed by the pod that has the rproxy service (acts as a hub).
- `local_replicas`: for local deployment with the rproxy service that acts as a hub to other services in other pods created as replicas (will act as a load balancer, accessing them with the same url, in a round robin fashion).
- `remote`: for remote deployment using a single host.
- `remote_hub`: for remote deployment using a single host with several pods accessed by the pod that has the rproxy service (acts as a hub).
- `remote_external_hub`: for remote deployment using a host with the rproxy service that acts as a hub to other hosts (will access each different host with a different url, going through the rproxy service).
- `remote_replicas`: for remote deployment using a host with the rproxy service that acts as a hub to other hosts created as replicas (will act as a load balancer, accessing them with the same url, in a round robin fashion).

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Reverse Proxy service.

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/rproxy.yml.

The following deployments can be seen at https://github.com/lucasbasquerotto/env-base/tree/master/docs/pod/rproxy.

### Minimal Deployment - Local

```yaml
name: "rproxy-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/rproxy.yml"
params:
  pod_custom_dir_sync: true
credentials: {}
```

### Minimal Deployment - Remote

```yaml
name: "rproxy-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/rproxy.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    rproxy: "rproxy.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "rproxy"
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
name: "rproxy-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/rproxy.yml"
params:
  rproxy_type: "haproxy"
  local_main_domain: "localhost"
  local_domains:
    rproxy: "localhost"
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
  use_secrets: false
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_local_s3: true
  use_fluentd: true
  use_outer_proxy: false
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: true
  use_secure_elasticsearch: false
  use_node_exporter: false
  use_pod_full_prefix: true
  block_ips: true
  define_s3_backup_lifecycle: true
  define_cron: true
  include_cron_watch: true
  enable_logs_backup: true
  enable_logs_setup: false
  enable_sync_backup: true
  enable_sync_setup: false
  enable_backup_replica: false
  local_standard_ports: false
  pod_custom_dir_sync: true
  inner_scripts_dir: ""
  named_volumes: false
  fluentd_output_plugin: "file"
  s3_cli: "mc"
  auth_file: "demo/auth/.htpasswd"
  auth_content:
    origin: "env"
    type: "file"
    file: "demo/auth/.mkpasswd"
  memory:
    nginx: 512mb
    haproxy: 512mb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    certbot: 256mb
    fluentd: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "rproxy-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/rproxy.yml"
params:
  app_hostname: "rproxy_app"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  rproxy_type: "haproxy"
  main_domain: "{{ params.your_domain }}"
  domains:
    rproxy: "rproxy.{{ params.your_domain }}"
    private: "private-rproxy.{{ params.your_domain }}"
    theia: "files-rproxy.{{ params.your_domain }}"
    minio_gateway: "s3-rproxy.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "rproxy"
    - record: "private-rproxy"
    - record: "files-rproxy"
    - record: "s3-rproxy"
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
  use_secrets: false
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_fluentd: true
  use_outer_proxy: false
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: true
  use_secure_elasticsearch: false
  use_node_exporter: false
  use_pod_full_prefix: true
  block_ips: true
  define_s3_backup_lifecycle: true
  define_cron: true
  include_cron_watch: true
  enable_logs_backup: true
  enable_logs_setup: false
  enable_sync_backup: true
  enable_sync_setup: false
  enable_backup_replica: false
  inner_scripts_dir: ""
  named_volumes: false
  fluentd_output_plugin: "file"
  s3_cli: "mc"
  outer_proxy_type: "cloudflare"
  auth_file: "demo/auth/.htpasswd"
  auth_content:
    origin: "env"
    type: "file"
    file: "demo/auth/.mkpasswd"
  internal_ssl:
    fullchain: "demo/ssl/internal.bundle.crt"
    cert: "demo/ssl/internal.crt"
    ca: "demo/ssl/internal.ca.crt"
    privkey: "demo/ssl/internal.key"
  host_ssh_public_keys_content:
    origin: "env"
    file: "demo/ssh/id_rsa.pub"
  memory:
    nginx: 512mb
    haproxy: 512mb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    certbot: 256mb
    fluentd: 256mb
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

The above configuration expects some files to be defined in the environment repository directory, that can be seen [here](../base/README.md#needed-environment-files).
