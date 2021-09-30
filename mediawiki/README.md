# Mediawiki

This example deploys a pod with containers containing a Mediawiki service connected to a MySQL database.

## Pod Parameters

TODO

## Deployment

There are 3 types of deployment of this pod:

- `app`: deploy all the containers in a single pod.
- `db`: deploy the MySQL container.
- `web`: deploy the Mediawiki container.

There are 3 cloud contexts that can be used:

- `local`: for local deployments.
- `remote`: for remote deployments using a single host (the pod type is `app`).
- `nodes`: for remote deployments using 2 hosts: pod types `web` (nginx + mediawiki) and `db` (mysql).

The following sections are examples of local and remote deployments. The minimal deployment has just the necessary stuff to run the Mediawiki and MySQL services (with Nginx, optionally).

The examples use the project environment base file https://github.com/lucasbasquerotto/env-base/tree/master/examples/mediawiki.yml.

The following deployments can be seen at https://github.com/lucasbasquerotto/env-base/tree/master/docs/pod/mediawiki.

### Minimal Deployment - Local

```yaml
name: "mediawiki-min-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/mediawiki.yml"
params:
  pod_custom_dir_sync: true
  mediawiki:
    logo: "https://www.mediawiki.org/static/images/project-logos/mediawikiwiki.png"
credentials:
  mediawiki:
    secret_key: "ce4e374745189efeeb2202833493c13242de589d59299f43f8325d59c7d4ebbe"
    db:
      root_password: "1234556"
      viewer_password: "123456"
      name: "my_wiki"
      user: "wikiuser"
      password: "AULT;1.2;AES2"
```

### Minimal Deployment - Remote

```yaml
name: "mediawiki-min-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/mediawiki.yml"
params:
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    mediawiki: "wiki.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "wiki"
  digital_ocean_node_region: "ams3"
  digital_ocean_node_size: "s-1vcpu-1gb"
  meta:
    ignore_validators: false
    skip_local_node_preparation: false
    skip_local_pod_preparation: false
    template_no_empty_lines: true
  use_nginx: true
  mediawiki:
    logo: "https://www.mediawiki.org/static/images/project-logos/mediawikiwiki.png"
  host_ssh_public_keys_content:
    origin: "env"
    file: "demo/ssh/id_rsa.pub"
credentials:
  mediawiki:
    secret_key: "ce4e374745189efeeb2202833493c13242de589d59299f43f8325d59c7d4ebbe"
    db:
      root_password: "1234556"
      viewer_password: "123456"
      name: "my_wiki"
      user: "wikiuser"
      password: "AULT;1.2;AES2"
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
name: "mediawiki-local"
ctxs: ["local"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/mediawiki.yml"
params:
  local_main_domain: "localhost"
  local_domains:
    mediawiki: "localhost"
    private: "private.localhost"
    phpmyadmin: "pma.localhost"
    adminer: "adminer.localhost"
    theia: "theia.localhost"
    minio_gateway: "s3.localhost"
  backup_bucket_name: "{{ params.backup_bucket_name }}"
  uploads_bucket_name: "{{ params.uploads_bucket_name }}"
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/mediawiki/db/20200612_181745.zip?raw=true"
  uploads_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/mediawiki/uploads/20200612_181745.zip?raw=true"
  meta:
    ignore_validators: true
    skip_local_node_preparation: true
    skip_local_pod_preparation: true
    template_no_empty_lines: true
  use_mediawiki_mail: true
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
    mediawiki: 1gb
    redis: 512mb
    memcached: 512mb
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
  mediawiki:
    secret_key: "ce4e374745189efeeb2202833493c13242de589d59299f43f8325d59c7d4ebbe"
    db:
      root_password: "1234556"
      viewer_password: "123456"
      name: "my_wiki"
      user: "wikiuser"
      password: "AULT;1.2;AES2"
  mediawiki_mail:
    address: "tls://smtp.sendgrid.net"
    port: "587"
    smtp_username: "apikey"
    smtp_password: "{{ params.sendgrid_password }}"
  s3: {}
  minio_gateway: {}
```

### Complete Deployment - Remote

```yaml
name: "mediawiki-remote"
ctxs: ["remote"]
env:
  repo:
    src: "https://github.com/lucasbasquerotto/env-base.git"
    version: "master"
  repo_dir: "env-base"
  file: "examples/mediawiki.yml"
params:
  app_hostname: "mediawiki_app"
  db_hostname: "mediawiki_db"
  cache_hostname: "mediawiki_cache"
  web_hostname: "mediawiki_web"
  private_ips: ["{{ params.private_ip }}"]
  cloud_service: "digital_ocean_vpn"
  node_service: "digital_ocean_node"
  dns_provider: "cloudflare"
  main_domain: "{{ params.your_domain }}"
  domains:
    mediawiki: "wiki.{{ params.your_domain }}"
    private: "private-wiki.{{ params.your_domain }}"
    phpmyadmin: "pma-wiki.{{ params.your_domain }}"
    adminer: "adminer-wiki.{{ params.your_domain }}"
    theia: "files-wiki.{{ params.your_domain }}"
    minio_gateway: "s3-wiki.{{ params.your_domain }}"
  dns_service_params_list:
    - record: "wiki"
    - record: "private-wiki"
    - record: "pma-wiki"
    - record: "adminer-wiki"
    - record: "files-wiki"
    - record: "s3-wiki"
  mediawiki:
    sitename: "My Wiki"
    meta_namespace: "MyWiki"
    logo: "https://www.mediawiki.org/static/images/project-logos/mediawikiwiki.png"
    emergency_contact: "noreply@wiki.example.com"
    password_sender: "noreply@wiki.example.com"
    lang: "en"
    authentication_token_version: "1"
    upload_path: ""
  db_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/mediawiki/db/20200612_181745.zip?raw=true"
  uploads_setup_restore_remote_file: "https://github.com/lucasbasquerotto/backups/blob/master/mediawiki/uploads/20200612_181745.zip?raw=true"
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
  use_mediawiki_mail: true
  use_pod_prefix: true
  use_secrets: true
  use_nginx: true
  use_varnish: true
  use_redis: false
  use_memcached: true
  use_pma: true
  use_adminer: true
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
  use_node_exporter: false
  use_pod_full_prefix: true
  non_s3_setup: true
  db_gui_root_user: true
  block_ips: true
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
  fluentd_output_plugin: "file"
  s3_cli: "awscli"
  outer_proxy_type: "cloudflare"
  auth_file: "demo/auth/.htpasswd"
  inner_scripts_dir: ""
  named_volumes: false
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
    mediawiki: 1gb
    redis: 512mb
    memcached: 512mb
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
  mediawiki:
    secret_key: "ce4e374745189efeeb2202833493c13242de589d59299f43f8325d59c7d4ebbe"
    db:
      root_password: "1234556"
      viewer_password: "123456"
      name: "my_wiki"
      user: "wikiuser"
      password: "AULT;1.2;AES2"
  mediawiki_mail:
    address: "tls://smtp.sendgrid.net"
    port: "587"
    smtp_username: "apikey"
    smtp_password: "{{ params.sendgrid_password }}"
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
