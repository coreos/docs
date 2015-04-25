---
layout: docs
slug: guides/etcd
title: Getting Started with etcd
category: distributed_configuration
sub_category: reading_writing
weight: 5
---

# Getting Started with etcd

etcd is an open-source distributed key value store that provides shared configuration and service discovery for CoreOS clusters. etcd runs on each machine in a cluster and gracefully handles master election during network partitions and the loss of the current master.

Application containers running on your cluster can read and write data into etcd. Common examples are storing database connection details, cache settings, feature flags, and more. This guide will walk you through a basic example of reading and writing to etcd then proceed to other features like TTLs, directories and watching a prefix. This guide is way more fun when you've got at least one CoreOS machine up and running &mdash; try it on [Amazon EC2]({{site.url}}/docs/running-coreos/cloud-providers/ec2) or locally with [Vagrant]({{site.url}}/docs/running-coreos/platforms/vagrant).

<a class="btn btn-default" href="{{site.url}}/docs/distributed-configuration/etcd-api/">Complete etcd API Docs</a>

## Reading and Writing to etcd

The HTTP-based API is easy to use. This guide will show both `etcdctl` and `curl` examples. It's important to note the `-L` flag is required for `curl`. etcd transparently redirects writes to the master and this flag allows `curl` to follow the location headers from etcd.

From a CoreOS machine, set a key `message` with value `Hello`:

```sh
$ etcdctl set /message Hello
Hello
```

```
$ curl -L -X PUT http://127.0.0.1:4001/v2/keys/message -d value="Hello"
{"action":"set","node":{"key":"/message","value":"Hello","modifiedIndex":4,"createdIndex":4}}
```

Read the value of `message` back:

```sh
$ etcdctl get /message
Hello
```

```sh
$ curl -L http://127.0.0.1:4001/v2/keys/message
{"action":"get","node":{"key":"/message","value":"Hello","modifiedIndex":4,"createdIndex":4}}
```

If you followed a guide to set up more than one CoreOS machine, you can SSH into another machine and can retrieve this same value.

To delete the key run:

```sh
$ etcdctl rm /message

```

```sh
$ curl -L -X DELETE http://127.0.0.1:4001/v2/keys/message
{"action":"delete","node":{"key":"/message","modifiedIndex":19,"createdIndex":4}}
```

## Reading and Writing from Inside a Container

To read and write to etcd from *within a container* you must use the IP address assigned to the `docker0` interface on the CoreOS host. From the host, run `ip address show` to find this address. It's normally `172.17.42.1`.

To read from etcd, replace `127.0.0.1` when running `curl` in the container:

```
$ curl -L http://172.17.42.1:4001/v2/keys/
{"action":"get","node":{"key":"/","dir":true,"nodes":[{"key":"/coreos.com","dir":true,"modifiedIndex":4,"createdIndex":4}]}}
```

You can also fetch the `docker0` IP programmatically:

```
ETCD_ENDPOINT="$(ifconfig docker0 | awk '/\<inet\>/ { print $2}'):4001"
```

## Proxy Example

Let's pretend we're setting up a service that consists of a few containers that are behind a proxy container. We can use etcd to announce these containers when they start by creating a directory, having each container write a key within that directory and have the proxy watch the entire directory. We're going to skip creating the containers here but the [docker guide]({{site.url}}/docs/launching-containers/building/getting-started-with-docker) is a good place to start for that.

### Create the directory

Directories are automatically created when a key is placed inside. Let's call our directory `foo-service` and create a key with information about a container:

```sh
$ etcdctl mkdir /foo-service
Cannot print key [/foo-service: Is a directory]
$ etcdctl set /foo-service/container1 localhost:1111
localhost:1111
```

```sh
$ curl -L -X PUT http://127.0.0.1:4001/v2/keys/foo-service/container1 -d value="localhost:1111"
{"action":"set","node":{"key":"/foo-service/container1","value":"localhost:1111","modifiedIndex":17,"createdIndex":17}}
```

Read the `foo-service` directory to see the entry:

```sh
$ etcdctl ls /foo-service
/foo-service/container1
```

```sh
$ curl -L http://127.0.0.1:4001/v2/keys/foo-service
{"action":"get","node":{"key":"/foo-service","dir":true,"nodes":[{"key":"/foo-service/container1","value":"localhost:1111","modifiedIndex":17,"createdIndex":17}],"modifiedIndex":17,"createdIndex":17}}
```

### Watching the Directory

Now let's try watching the `foo-service` directory for changes, just like our proxy would have to. First, open up another shell on a CoreOS host in the cluster. In one window, start watching the directory and in the other window, add another key `container2` with the value `localhost:2222` into the directory. This command shouldn't output anything until the key has changed. Many events can trigger a change, including a new, updated, deleted or expired key.

```sh
$ etcdctl watch /foo-service --recursive

```

```sh
$ curl -L http://127.0.0.1:4001/v2/keys/foo-service?wait=true\&recursive=true

```

In the other window, let's pretend a new container has started and announced itself to the proxy by running:

```sh
$ etcdctl set /foo-service/container2 localhost:2222
localhost:2222
```

```sh
$ curl -L -X PUT http://127.0.0.1:4001/v2/keys/foo-service/container2 -d value="localhost:2222"
{"action":"set","node":{"key":"/foo-service/container2","value":"localhost:2222","modifiedIndex":23,"createdIndex":23}}
```

In the first window, you should get the notification that the key has changed. In a real application, this would trigger reconfiguration.

```sh
$ etcdctl watch /foo-service --recursive
localhost:2222
```

```sh
$ curl -L http://127.0.0.1:4001/v2/keys/foo-service?wait=true\&recursive=true
{"action":"set","node":{"key":"/foo-service/container2","value":"localhost:2222","modifiedIndex":23,"createdIndex":23}}
```

## Test and Set

etcd can be used as a centralized coordination service and provides `TestAndSet` functionality as the building block of such a service. You must provide the previous value along with your new value. If the previous value matches the current value the operation will succeed.

```sh
$ etcdctl set /message "Hi" --swap-with-value "Hello"
Hi
```

```sh
$ curl -L -X PUT http://127.0.0.1:4001/v2/keys/message?prevValue=Hello -d value=Hi
{"action":"compareAndSwap","node":{"key":"/message","value":"Hi","modifiedIndex":28,"createdIndex":27}}
```

## TTL

You can optionally set a TTL for a key to expire in a certain number of seconds. Setting a TTL of 20 seconds:

```sh
$ etcdctl set /foo "Expiring Soon" --ttl 20
Expiring Soon
```

The `curl` response will contain an absolute timestamp of when the key will expire and a relative number of seconds until that timestamp:

```sh
$ curl -L -X PUT http://127.0.0.1:4001/v2/keys/foo?ttl=20 -d value=bar
{"action":"set","node":{"key":"/foo","value":"bar","expiration":"2014-02-10T19:54:49.357382223Z","ttl":20,"modifiedIndex":31,"createdIndex":31}}
```

If you request a key that has already expired, you will be returned a 100:

```sh
$ etcdctl get /foo
Error: 100: Key not found (/foo) [32]
```

```sh
$ curl -L http://127.0.0.1:4001/v2/keys/foo
{"errorCode":100,"message":"Key not found","cause":"/foo","index":32}
```

#### More Information
<a class="btn btn-default" href="{{site.url}}/using-coreos/etcd">etcd Overview</a>
<a class="btn btn-default" href="https://github.com/coreos/etcd">Full etcd API Docs</a>
<a class="btn btn-default" href="https://github.com/coreos/etcd/blob/master/Documentation/libraries-and-tools.md">Projects using etcd</a>
