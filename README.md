# (Under Construction) Pod Layer (Extension)

This repository constitute the pod layer and  is used to deploy services inside containers in a given host. It extends the pod repository defined at http://github.com/lucasbasquerotto/pod providing real world pod examples.

## Demo

Before start using this layer, it's easier to see it in action. Below is a simple demo used to deploy a project. The demo uses pre-defined [input variables](#cloud-input-vars), uses a cloud layer to deploy a project and then uses this layer to define the deployed pod.

To execute the demo more easily you will need a container engine (like `docker` or `podman`).

1. Create an empty directory somewhere in your filesystem, let's say, `/var/demo`.

2. Create 2 directories in it: `env` and `data` (the names could be different, just remember to use these directories when mapping volumes to the container).

3. Create a `demo.yml` file inside `env` with the data needed to deploy the project:

```yaml
# Enter the data here (see the demo examples)
```

4. Deploy the project:

```shell
docker run -it --rm -v /var/demo/env:/env:ro -v /var/demo/data:/lrd local/demo
```

**The above commands in a shell script:**

```shell
mkdir -p /var/demo/env /var/demo/data

cat <<'SHELL' > /var/demo/env/demo.yml
# Enter the data here (see the demo examples)
SHELL

docker run -it --rm -v /var/demo/env:/env:ro -v /var/demo/data:/lrd local/demo
```

**That's it. The project was deployed.**

🚀 You can see examples of project deployment demos [here](#TODO).

The demos are great for what they are meant to be: demos, prototypes. **They shouldn't be used for development** (bad DX if you need real time changes without having to push and pull newer versions of repositories, furthermore you are unable to clone repositories in specific locations defined by you in the project folder). **They also shouldn't be used in production environments** due to bad security (the vault value used for decryption is `123456`, and changes to the [project environment repository](#project-environment) may be lost if you forget to push them).

## About this repository

This repository expects the services to run inside containers because they are easier to organize and upgrade. Containers avoid package conflicts in the host and help in isolating services dependencies.

Most of the examples in this repository follow the conventions described in the [base pod](base) example.

There are several different real world examples of deployments that can be done using this repository:

- [Ghost](/ghost)
- [Mattermost](/mattermost)
- [Mediawiki](/mediawiki)
- [Prometheus](/prometheus)
- [Rocketchat](/rocketchat)
- [Wordpress](/wordpress)

There are also examples that are not recommended to be used in a real world deployment yet, but can used in local and remote deployments when in development or in tests.

- [Elasticsearch](/efk)
- [Minio](/minio)
- [Vault](/vault)