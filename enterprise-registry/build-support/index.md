---
layout: docs
title: Dockerfile Build Setup
category: registry
sub_category: setup
forkurl: https://github.com/coreos/docs/blob/master/enterprise-registry/build-support/index.md
weight: 5
---

# Dockerfile Build Support

CoreOS Enterprise Registry supports building Dockerfiles using a set of worker nodes.

*Note:* This feature is currently in *beta*, so it may encounter issues every so often. Please report
any issues encountered to support so we can fix it ASAP.

## Change the feature flag

In the Enteprise Registry `config.yaml`, change the following to enable build support:

```yaml
FEATURE_BUILD_SUPPORT: false
```

to

```yaml
FEATURE_BUILD_SUPPORT: true
```

## Update and Restart Enterprise Registry

Pull the latest Enterprise Registry image and restart the CoreOS Enterprise Registry to enable building.

## Setup the build worker(s)

Select one (or more) machines to be used as your build workers. The machines must have Docker installed and must
not be used for any other work. The following procedure needs to be done everytime a new worker needs to be
added, but it can be automated fairly easily.

### Download the Build Worker image

```sh
docker pull quay.io/coreos/registry-build-worker:latest
```

### Run the Build Worker image

`docker run` the image, with `SERVER` being a *websocket URL* to your Enterprise Registry install. For example,
if your Enterprise Registry is located at `somehost.com`, then the `SERVER` will be:

- If SSL is being used: ```wss://somehost.com```
- If SSL is *not* being used: ```ws://somehost.com```

```sh
docker run --restart on-failure -e SERVER=wss://myenterprise.host -v /var/run/docker.sock:/var/run/docker.sock quay.io/coreos/registry-build-worker:latest
```

The build worker should auto-register with the Enterprise Registry and start building once a job has been queued.

### Setup GitHub Build (optional)

If your organization plans to have builds be conducted via pushes to GitHub (or GitHub Enterprise), please continue
with the <a href="../github-build/">Setting up Github Build</a>.

