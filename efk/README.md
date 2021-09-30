# EFK (Elasticsearch + Fluentd + Kibana)

This example deploys a pod with containers containing the following services:

- Elasticsearch
- Fluentd
- Kibana

The only service required (of the services above) is Elasticsearch. The Kibana service can be included with the option `use_kibana: true` and the Fluentd service can be included with the option `use_fluentd: true` and `use_internal_fluentd: true` (the later with a `true` value means that the fluentd service is in the pod, otherwise the containers will try to connect with an external fluentd service in the host, or in another pod in the host). The Fluentd service, in this case, is used by the containers in the pod. To use fluentd in other pods, the fluentd service must be included (separately) in them.

## Deployment

There are 3 types of deployment of this pod:

- `app`: deploy all the containers in a single pod.
- `db`: deploy the Elasticsearch container.
- `web`: deploy the Kibana container.

There are 3 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host (the pod type is `app`).
- `nodes`: for remote deployments using 2 hosts: pod types `web` (nginx + kibana) and `db` (elasticsearch).

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Elasticsearch service with Kibana and Nginx, although the later 2 are not actually needed.

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/efk.yml

### Minimal Deployment - Local

```yaml
name: "efk-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/efk.yml"
params:
  pod_custom_dir_sync: true
  use_kibana: true
  use_nginx: true
credentials: {}
```

### Minimal Deployment - Remote

```yaml
name: "efk-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/efk.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    kibana: "log.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "log"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-2vcpu-2gb"
  meta:
    template_no_empty_lines: true
  use_kibana: true
  use_nginx: true
  host_ssh_public_keys_content:
    origin: "env"
    file: "ssh/id_rsa.pub"
credentials:
  host:
    host_user: "host"
    host_pass: "111222"
    ssh_file: "ssh/id_rsa"
  digital_ocean:
    api_token: "{{ params.digital_ocean_api_token }}"
  cloudflare:
    email: "{{ params.cloudflare_email }}"
    token: "{{ params.cloudflare_token }}"
```

### Complete Deployment - Local

```yaml
name: "efk-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/efk.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    kibana: "localhost"
    private: "private.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  backup_bucket_name: "efk-backup"
  snapshot_name: "snapshot-20200813-230131"
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/efk/db/20200813_230132.zip?raw=true"
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
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: true
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
  auth_file: "files/auth/.htpasswd"
  fluentd_output_plugin: "elasticsearch"
  local_custom_ssl:
    fullchain: "ssl/internal.bundle.crt"
    cert: "ssl/internal.crt"
    ca: "ssl/internal.ca.crt"
    privkey: "ssl/internal.key"
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
```

### Complete Deployment - Remote

```yaml
name: "efk-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/efk.yml"
params:
  app_hostname: "efk_app"
  db_hostname: "efk_db"
  web_hostname: "efk_web"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    kibana: "log.{{ params.your_domain }}"
    private: "private-log.{{ params.your_domain }}"
    theia: "files-log.{{ params.your_domain }}"
    minio_gateway: "s3-log.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "log"
    - record: "private-log"
    - record: "files-log"
    - record: "s3-log"
  dns_elasticsearch_params_list:
    - record: "elasticsearch"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-2vcpu-2gb"
  certbot_email: "{{ params.certbot_email }}"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  meta:
    template_no_empty_lines: true
  run_dns_main: false
  use_pod_prefix: true
  use_secrets: false
  use_kibana: true
  use_theia: true
  use_minio_gateway: true
  use_s3: true
  use_nginx: true
  use_fluentd: true
  use_certbot: true
  use_private_path: true
  use_basic_auth_private: true
  use_ssl: false
  use_secure_elasticsearch: true
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
  host:
    host_user: "host"
    host_pass: "111222"
    ssh_file: "ssh/id_rsa"
  elasticsearch:
    elastic_password: "111111"
    kibana_system_password: "222222"
    kibana_admin_password: "333333"
    fluentd_password: "444444"
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

## Pod Parameters

TODO