---
layout: docs
title: Automatically Build Dockerfiles
category: registry
sub_category: setup
forkurl: https://github.com/coreos/docs/blob/master/enterprise-registry/build-support/index.md
weight: 5
---

# Automatically build Dockerfiles with Build Workers

CoreOS Enterprise Registry supports building Dockerfiles using a set of worker nodes. Build triggers, such as GitHub webhooks ([Setup Instructions]({{site.url}}/docs/enterprise-registry/github-build)), can be configured to automatically build new versions of your repositories when new code is committed. This document will walk you through enabling the feature flag and setting up multiple build workers to enable this feature.

<img src="workers.png" class="img-center" alt="Enterprise Registry Build Workers"/>

*Note:* This feature is currently in *beta*, so it may encounter issues every so often. Please report
any issues encountered to support so we can fix it ASAP.

## Enable the Feature Flag

By default, the feature flag to enable build workers is off. In the Enterprise Registry `config.yaml`, change the following to enable build support:

```yaml
FEATURE_BUILD_SUPPORT: false
```

to

```yaml
FEATURE_BUILD_SUPPORT: true
```

### Update and Restart Enterprise Registry

If you're running an older version of the Enterprise Registry container, pull down a new copy:

```sh
docker pull quay.io/coreos/registry
```

During the Enterprise Registry set up process, you were provided credentials to access this image. If your server has these configured, they will be used. If you get an authentication error, you may need to [set up the]({{site.url}}/docs/enterprise-registry/initial-setup/) `.dockercfg` file again.

To apply the new configuration, restart the container running the registry.

## Setup the Build Workers

One or more build workers will communicate with the main registry container to build new containers when triggered. The machines must have Docker installed and must not be used for any other work. The following procedure needs to be done every time a new worker needs to be
added, but it can be automated fairly easily.

### Pull the Build Worker Image

The build worker is currently in beta. To gain access to its repository, please contact support.
Once given access, pull down the latest copy of the image just like any other:

```sh
docker pull quay.io/coreos/registry-build-worker:latest
```

### Run the Build Worker image

Run this container on each build worker. Since the worker will be orchestrating docker builds, we need to mount in the docker socket. This orchestration will use a large amount of CPU and need to manipulate the docker images on disk &mdash; we recommend that dedicated machines be used for this task.

Use the environment variable `SERVER` to tell the worker how to communicate with the primary Enterprise Registry container. A websocket is used as a data channel, and it was configured when we changed the feature flag above.

| Security | Websocket Address |
|----------|-------------------|
| Using SSL | ```wss://somehost.com``` |
| Without SSL | ```ws://somehost.com```

Here's what the full command looks like:

```sh
docker run --restart on-failure -e SERVER=wss://myenterprise.host -v /var/run/docker.sock:/var/run/docker.sock quay.io/coreos/registry-build-worker:latest
```

When the container starts, each build worker will auto-register with the Enterprise Registry and start building containers once a job triggered and it is assigned to a worker.

### Setup GitHub Build (optional)

If your organization plans to have builds be conducted via pushes to GitHub (or GitHub Enterprise), please continue
with the <a href="../github-build/">Setting up Github Build</a>.

