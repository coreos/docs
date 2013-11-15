---
layout: docs
slug: guides/etcd
title: Documentation - etcd
---

# Getting Started with etcd

etcd is an open-source distributed key value store that provides shared configuration and service discovery for CoreOS clusters. etcd runs on each machine in a cluster and gracefully handles master election during network partitions and the loss of the current master.

Application containers running on your cluster can read and write data into etcd. Common examples are storing database connection details, cache settings, feature flags, and more. This guide will walk you through a basic example of reading and writing to etcd then proceed to other features like TTLs, directories and watching a prefix. This guide is way more fun when you've got at least one CoreOS machine up and running &mdash; try it on [Amazon EC2]({{site.url}}/docs/ec2/) or locally with [Vagrant]({{site.url}}/docs/vagrant).

<a class="btn btn-default" href="https://github.com/coreos/etcd#etcd">Complete etcd API Docs</a>

## Reading and Writing to etcd

The API is easy to use. From a CoreOS machine, you can simply use curl to set and retrieve a key from etcd. It's important to note the `-L` flag is required. etcd transparently redirects writes to the master and this flag allows curl to follow the location headers from etcd.

Set a key `message` with value `Hello`:

```
curl -L http://127.0.0.1:4001/v1/keys/message -d value="Hello"
```

Read the value of `message` back:

```
curl -L http://127.0.0.1:4001/v1/keys/message
```

If you followed a guide to set up more than one CoreOS machine, you can SSH into another machine and can retrieve this same value. To delete the key run:

```
curl -L http://127.0.0.1:4001/v1/keys/message -X DELETE
```

## Reading and Writing from Inside a Container

To read and write to etcd from *within a container* you must use the `docker0` interface which you can find in `ifconfig`. It's normally `172.17.42.1` and using it is as easy as replacing `127.0.0.1`.

## Proxy Example

Let's pretend we're setting up a service that consists of a few containers that are behind a proxy container. We can use etcd to announce these containers when they start by creating a directory, having each container write a key within that directory and have the proxy watch the entire directory. We're going to skip creating the containers here but the [docker guide]({{site.url}}/docs/docker) is a good place to start for that.

### Create the directory

Directories are automatically created when a key is placed inside. Let's call our directory `foo-service` and create a key with information about a container:

```
curl -L http://127.0.0.1:4001/v1/keys/foo-service/container1 -d value="localhost:1111"
```

Read the `foo-service` directory to see the entry:

```
curl -L http://127.0.0.1:4001/v1/keys/foo-service
```

### Watching the Directory

Now let's try watching the `foo-service` directory for changes, just like our proxy would have to. First, open up another shell on a CoreOS host in the cluster. In one window, start watching the directory by changing `keys` to `watch`. This command shouldn't output anything until the key has changed. Many events can trigger a change, including a new, updated, deleted or expired key.

```
curl -L http://127.0.0.1:4001/v1/watch/foo-service
```

In the other window, let's pretend a new container has started and announced itself to the proxy by running:

```
curl -L http://127.0.0.1:4001/v1/keys/foo-service/container2 -d value="localhost:2222"
```

In the first window, you should get the notification that the key has changed. In a real application, this would trigger reconfiguration.

## Test and Set

etcd can be used as a centralized coordination service and provides `TestAndSet` functionality as the building block of such a service. You must provide the `prevValue` along with your new value. If the previous value matches the current value the operation will succeed.

```
curl -L http://127.0.0.1:4001/v1/keys/message -d prevValue=Hello -d value=Hi
```

## TTL

You can optionally set a TTL for a key to expire in a certain number of seconds. Setting a TTL of 5 seconds:

```
curl -L http://127.0.0.1:4001/v1/keys/foo -d value=bar -d ttl=5
```

The response will contain an absolute timestamp of when the key will expire and a relative number of seconds until that timestamp:

```
{"action":"SET","key":"/foo","value":"bar","newKey":true,"expiration":"2013-07-11T20:31:12.156146039-07:00","ttl":4,"index":6}
```

If you request a key that has already expired, you will be returned a 100:

```
{"errorCode":100,"message":"Key Not Found","cause":"/foo"}
```

#### More Information
<a class="btn btn-default" href="{{site.url}}/using-coreos/etcd">etcd Overview</a>
<a class="btn btn-default" href="https://github.com/coreos/etcd">Full etcd API Docs</a>
<a class="btn btn-default" href="https://github.com/coreos/etcd#libraries-and-tools">Projects using etcd</a>
