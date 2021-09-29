# Base Pod

TODO

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
