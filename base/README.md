# Base Pod

This is a basic example of a pod that has an Nginx service that returns a static response.

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

```

### Minimal Deployment - Remote

```yaml

```

### Complete Deployment - Local

```yaml

```

### Complete Deployment - Remote

```yaml

```

The above configuration expects some files to be defined in the environment repository directory, that can be seen [here](#needed-environment-files).

# Needed Environment Files

Some configurations expect that certain files be generated and referenced beforehand.

By defining `use_basic_auth_private: true`, the private services expect basic authentication, whose file should be defined at:

- `auth/.htpasswd`

*(To generate a basic authentication file with a user `user1`, run the command `htpasswd /path/to/.htpasswd user1`)*

By defining `use_secure_elasticsearch: true`, the elasticsearch service will expect secure connection. The certificates must be defined in the following files:

- `ssl/internal.bundle.crt`
- `ssl/internal.crt`
- `ssl/internal.ca.crt`
- `ssl/internal.key`

The SSH public and private files should be defined at, respectively:

- `ssh/id_rsa.pub`
- `ssh/id_rsa`

*(To generate the SSH files, run `ssh-keygen -t rsa`, then move the generated files to the `ssh` folder in the environment repository directory)*
