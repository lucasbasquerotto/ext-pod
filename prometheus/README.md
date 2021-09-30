# Prometheus

This example deploys a pod with containers containing a Prometheus and other optional services (each in its own container), the most notable being Grafana.

## Pod Parameters

TODO

## Deployment

There are 3 types of deployment of this pod:

- `app`: deploy all the containers in a single pod.
- `db`: deploy the Prometheus container.
- `web`: deploy the Grafana container.

There are 3 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host (the pod type is `app`).
- `nodes`: for remote deployments using 2 hosts: pod types `web` (nginx + grafana) and `db` (prometheus).

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Prometheus service with Grafana and Nginx, although the later 2 are not actually needed.

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/prometheus.yml.

The following deployments can be seen at https://github.com/lucasbasquerotto/env-base/tree/master/docs/pod/prometheus.

### Minimal Deployment - Local

```yaml
name: "prometheus-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/prometheus.yml"
params:
  local_domains:
    grafana: "localhost"
    prometheus: "prometheus.localhost"
  pod_custom_dir_sync: true
  use_nginx: true
  use_grafana: true
credentials:
  grafana:
    security_admin_password: "123456"
    server_domain: "localhost"
    smtp_enabled: true
    smtp_host: "smtp.sendgrid.net:587"
    smtp_user: "apikey"
    smtp_password: "123456"
    smtp_from_address: "noreply@example.com"
```

### Minimal Deployment - Remote

```yaml
name: "prometheus-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/prometheus.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    grafana: "monitor.{{ params.your_domain }}"
    prometheus: "prometheus-monitor.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "monitor"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  meta:
    ignore_validators: false
    skip_local_node_preparation: false
    skip_local_pod_preparation: false
    template_no_empty_lines: true
  use_nginx: true
  use_grafana: true
  host_ssh_public_keys_content:
    origin: "env"
    file: "demo/ssh/id_rsa.pub"
credentials:
  grafana:
    security_admin_password: "123456"
    server_domain: "monitor.{{ params.your_domain }}"
    smtp_enabled: true
    smtp_host: "smtp.sendgrid.net:587"
    smtp_user: "apikey"
    smtp_password: "123456"
    smtp_from_address: "noreply@monitor.{{ params.your_domain }}"
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
name: "prometheus-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/prometheus.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    grafana: "localhost"
    prometheus: "prometheus.localhost"
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
  use_nginx: true
  use_grafana: true
  use_cadvisor: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_local_s3: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: false
  use_node_exporter: true
  use_internal_node_exporter: true
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
  prometheus_external_port: "9090"
  pod_custom_dir_sync: true
  inner_scripts_dir: ""
  named_volumes: false
  fluentd_output_plugin: "file"
  s3_cli: "awscli"
  auth_file: "demo/auth/.htpasswd"
  memory_app:
    nginx: 512mb
    grafana: 512mb
    prometheus: 1gb
    node_exporter: 512mb
    cadvisor: 512mb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  grafana:
    security_admin_password: "123456"
    server_domain: "localhost"
    smtp_enabled: true
    smtp_host: "smtp.sendgrid.net:587"
    smtp_user: "apikey"
    smtp_password: "{{ params.sender_email }}"
    smtp_from_address: "noreply@example.com"
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "prometheus-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/prometheus.yml"
params:
  app_hostname: "prometheus_app"
  db_hostname: "prometheus_db"
  web_hostname: "prometheus_web"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  prometheus_url: "http://prometheus.{{ params.your_domain }}:9090"
  domains:
    grafana: "monitor.{{ params.your_domain }}"
    prometheus: "prometheus-monitor.{{ params.your_domain }}"
    private: "private-monitor.{{ params.your_domain }}"
    theia: "files-monitor.{{ params.your_domain }}"
    minio_gateway: "s3-monitor.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "monitor"
    - record: "prometheus-monitor"
    - record: "private-monitor"
    - record: "files-monitor"
    - record: "s3-monitor"
  dns_prometheus_params_list:
    - record: "prometheus"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  certbot_email: "{{ params.certbot_email }}"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  meta:
    ignore_validators: false
    skip_local_node_preparation: false
    skip_local_pod_preparation: false
    template_no_empty_lines: true
  run_nameserver_main: false
  run_dns_main: false
  use_pod_prefix: true
  use_secrets: false
  use_nginx: true
  use_grafana: true
  use_cadvisor: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: false
  use_node_exporter: true
  use_internal_node_exporter: true
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
  prometheus_external_port: "9090"
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
    grafana: 512mb
    prometheus: 1gb
    node_exporter: 512mb
    cadvisor: 512mb
    theia: 512mb
    minio_gateway: 512mb
    toolbox: 512mb
    fluentd: 256mb
    certbot: 256mb
    logrotator: 256mb
    s3_cli: 512mb
credentials:
  grafana:
    security_admin_password: "123456"
    server_domain: "monitor.{{ params.your_domain }}"
    smtp_enabled: true
    smtp_host: "smtp.sendgrid.net:587"
    smtp_user: "apikey"
    smtp_password: "{{ params.sender_email }}"
    smtp_from_address: "noreply@monitor.{{ params.your_domain }}"
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
