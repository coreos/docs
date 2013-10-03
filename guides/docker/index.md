---
layout: docs
slug: guides/docker
title: Documentation - docker
forkurl: 
---

# docker


## Overview

docker is an open-source project that makes creating and managing Linux containers (LXC) really easy. Containers are like extremely lightweight VMs – they allow code to run in isolation from other containers but safely share the machine’s resources, all without the overhead of a hypervisor.

docker containers can boot extremely fast (in milliseconds!) which gives you unprecedented flexibility in managing load across your cluster. For example, instead of running chef on each of your VMs, it’s faster and more reliable to have your build system create a container and launch it on the appropriate number of CoreOS hosts. This guide will show you how to launch a container, install some software on it, commit that container, and optionally launch it on another CoreOS machine. Before starting, make sure you've got at least one CoreOS machine up and running &mdash; try it on [Amazon EC2](docs/ec2/) or locally with [Vagrant](docs/vagrant).

## Docker CLI Basics

docker has a [straightforward CLI](http://docs.docker.io/en/latest/commandline/cli/) that allows you to do almost everything you could want to a container. All of these commands use the image id (ex. be29975e0098), the image name (ex. myusername/webapp) and the container id (ex. 72d468f455ea) interchangable depending on the operation you are trying to do. This is confusing at first, so pay special attention to what you're using.

## Launching a Container

Launching a container is simple as `docker run` + the image name you would like to run + the command to run within the container. If the image doesn't exist on your local machine, docker will attempt to fetch it from the public image registry. Later we'll explore how to use docker with a private registry. It's important to note that containers are designed to stop once the command executed within them has exited. For example, if you ran `/bin/echo hello world` as your command, the container will start, print hello world and then stop:

```
docker run ubuntu /bin/echo hello world
```

Let's launch an ubuntu container and install apache inside of it using the bash prompt:

```
docker run -t -i ubuntu /bin/bash
```

The `-t` and `-i` flags allocate a pseudo-tty and keep stdin open even if not attached. This will allow you to use the container like a traditional VM as long as the bash prompt is running. Install apache with `apt-get install apache2`. You're probably wondering what address you can connect to in order to test that apache was correctly installed...we'll get to that after we commit the container.
```

## Commiting a Container

After that completes, we need to `commit` these changes to our container with the container ID and the image name. Fetch the container id using `docker ps` in another shell. Remember, the image name is in the format of `username/name`...we're going to use `coreos` in this example. Insert the id with the image name you'd like to use:

```
docker commit 72d468f455ea coreos/apache
```

The overlay filesystem works similar to git: our image now builds off of the `ubuntu` base and adds another layer with apache on top. These layers get cached separately so that you won't have to pull down the ubuntu base more than once.

## Keeping the Apache Container Running

Now we have our ubuntu container with apache running in one shell and an image of that container sitting on disk. Let's launch a new container based on that image but set it up to keep running indefinitely. The basic syntax looks like this, but we need to configure a few additional options that we'll fill in as we go:

```
docker run [options] [image] [process]
```

The first step is to tell docker that we want to run our `coreos/apache` image:

```
docker run [options] coreos/apache [process]
```

### Run Container Detached

The most important option is to run the container in detached mode with the `-d` flag. This will output the container ID to show that the command was successful, but nothing else. At any time you can run `docker ps` in the other shell to view a list of the running containers. Our command now looks like:

```
docker run -d coreos/apache [process]
```

### Run Apache in Foreground

We need to run the apache process in the foreground, since our container will stop when the process specified in the `docker run` command stops. We can do this with a flag `-D` when starting the apache2 process:

```
/usr/sbin/apache2 -D
```

Let's add that to our command:

```
docker run -d coreos/apache /usr/sbin/apache2 -D
```

### Network Access to 80

The default apache install will be running on port 80. To give our container access to traffic over port 80, we use the `-p` flag and specify the port on the host that maps to the port inside the container. In our case we want 80 for each, so we include `-p 80:80` in our command:

```
docker run -d -p 80:80 coreos/apache /usr/sbin/apache2 -D 
```

You can now run this command on your CoreOS host to create the container. You should see the default apache webpage when you load either `localhost:80` or the IP of your remote server. Be sure that any firewall or EC2 Security Group allows traffic to port 80.

## Using the Docker Registry

Earlier we downloaded the ubuntu image remotely from the docker public registry because it didn't exist on our local machine. We can also push local images to the public registry (or a private registry) very easily with the `push` command:

```
docker push coreos/apache
```

To push to a private repository the syntax is very similar. First, we must prefix our image with the host running our private registry instead of our username. List images by running `docker images` and insert the correct ID into the `tag` command:

```
docker tag f455ea72d468 registry.domain.com:5000/apache
```

After tagging, the image needs to be pushed to the registry:

```
docker push registry.domain.com:5000/apache
```

Once the image is done uploading, you should be able to start the exact same container on a different CoreOS host by running:

```
docker run -d -p 08:80 registry.domain.com:5000/apache /usr/sbin/apache2 -D
```

#### More Information
<a class="btn btn-default" href="http://coreos.com/using-coreos/etcd">etcd Overview</a>
<a class="btn btn-default" href="https://github.com/coreos/etcd">Full etcd API Docs</a>
<a class="btn btn-default" href="https://github.com/coreos/etcd#libraries-and-tools">Projects using etcd</a>
