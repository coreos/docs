# Automatically build Dockerfiles with build workers

Quay Enterprise supports building Dockerfiles using a set of worker nodes. Build triggers, such as GitHub webhooks ([Setup Instructions](github-build.md)), can be configured to automatically build new versions of your repositories when new code is committed. This document will walk you through enabling the feature flag and setting up multiple build workers to enable this feature.

## Visit the management panel

Sign in to a super user account and visit `http://yourregister/superuser` to view the management panel:

<img src="img/superuser.png" class="img-center" alt="Quay Enterprise Management Panel"/>

## Enable Building

<img src="img/enable-build.png" class="img-center" alt="Enable Dockerfile Build"/>

- Click the configuration tab (<span class="fa fa-gear"></span>) and scroll down to the section entitled **Dockerfile Build Support**.
- Check the "Enable Dockerfile Build" box
- Click "Save Configuration Changes"
- Restart the container (you will be prompted)

## Setup the build workers

<img src="img/workers.png" class="img-center" alt="Quay Enterprise Build Workers"/>

One or more build workers will communicate with Quay Enterprise to build new containers when triggered. The machines must have Docker installed and must not be used for any other work. The following procedure needs to be done every time a new worker needs to be added, but it can be automated fairly easily.

### Pull the build worker image

Pull down the latest copy of the image. **Make sure to pull the version tagged matching your Quay Enterprise version**.

```sh
docker pull quay.io/coreos/quay-builder:v2.8.0
```

### Run the build worker image

Run this container on each build worker. Since the worker will be orchestrating docker builds, we need to mount in the docker socket. This orchestration will use a large amount of CPU and need to manipulate the docker images on disk &mdash; we recommend that dedicated machines be used for this task.

Use the environment variable `SERVER` to tell the worker the hostname at which Quay Enterprise is accessible:

| Security | Websocket Address |
|----------|-------------------|
| Using SSL | ```wss://your.quayenterprise.dnsname``` |
| Without SSL | ```ws://your.quayenterprise.dnsname``` |

Here's what the full command looks like:

```sh
docker run --restart on-failure -e SERVER=ws://myquayenterprise -v /var/run/docker.sock:/var/run/docker.sock quay.io/coreos/quay-builder:v2.8.0
```

When the container starts, each build worker will auto-register and start building containers once a job is triggered and it is assigned to a worker.

If Quay is setup to use a SSL certificate that is not globally trusted, for example a self-signed certificate, Quay's public SSL certificates must be mounted onto the `quay-builder` container's SSL trust store. An example command to mount a certificate found at the host's `/path/to/ssl/rootCA.pem` looks like:

```sh
docker run --restart on-failure -e SERVER=wss://myquayenterprise -v /path/to/ssl/rootCA.pem:/usr/local/share/ca-certificates/rootCA.pem -v /var/run/docker.sock:/var/run/docker.sock --entrypoint /bin/sh quay.io/coreos/quay-builder:v2.8.0 -c '/usr/sbin/update-ca-certificates && quay-builder'
```

The logs of the quay-builder container can provide insight into the build related issues. It can be useful configure a log driver to aggregate and archive these logs. This can be done by passing a `--log-driver` flag in the `docker run` comand or configuring a logging driver via the Docker daemon. 

### Setup GitHub build (optional)

If your organization plans to have builds be conducted via pushes to GitHub (or GitHub Enterprise), please continue
with the [Setting up GitHub Build](github-build.md).
