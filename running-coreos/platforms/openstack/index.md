---
layout: docs
title: OpenStack
category: running_coreos
sub_category: platforms
weight: 5
---

# Running CoreOS on OpenStack

CoreOS is currently in heavy development and actively being tested.  These
instructions will walk you through downloading CoreOS for OpenStack, importing
it with the `glance` tool and running your first cluster with the `nova` tool.

## Import the Image

These steps will download the CoreOS image, uncompress it and then import it
into the glance image store.

```
$ wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
$ glance image-create --name CoreOS \
  --container-format ovf \
  --disk-format qcow2 \
  --file coreos_production_openstack_image.img \
  --is-public True
+------------------+--------------------------------------+
| Property         | Value                                |
+------------------+--------------------------------------+
| checksum         | 4742f3c30bd2dcbaf3990ac338bd8e8c     |
| container_format | ovf                                  |
| created_at       | 2013-08-29T22:21:22                  |
| deleted          | False                                |
| deleted_at       | None                                 |
| disk_format      | qcow2                                |
| id               | cdf3874c-c27f-4816-bc8c-046b240e0edd |
| is_public        | True                                 |
| min_disk         | 0                                    |
| min_ram          | 0                                    |
| name             | coreos                               |
| owner            | 8e662c811b184482adaa34c89a9c33ae     |
| protected        | False                                |
| size             | 363660800                            |
| status           | active                               |
| updated_at       | 2013-08-29T22:22:04                  |
+------------------+--------------------------------------+
```

## Cluster Setup

We'll walk you through launching and configuring three instances of CoreOS and
using User Data injection to configure etcd cluster discovery. In order for this
to work your OpenStack cloud provider must be running the OpenStack metadata
service.

1. You need to specify a discovery URL, which contains a unique token that allows
   instances to find other hosts in the cluster. If you're launching your first
   instance, generate one at [https://discovery.etcd.io/new](https://discovery.etcd.io/new)
   and add it to the metadata. You should use this key for each machine in the
   cluster. You'll use this token in a file to configure the User Data of new
   instances. An example file is here (referenced as userdata.txt later):

        #!/bin/sh
        ETCD_DISCOVERY_URL=https://discovery.etcd.io/<token>
        START_FLEET=1

2. Now generate the ssh key that will be injected into the image for the `core`
   user

        $ nova keypair-add coreos > core.pem

3. Boot up the cluster.
   Note: Specify the id of the image we imported. The name of the key we just
   created and the user-data file.

        $ nova boot \
          --user-data ./userdata.txt \
          --image cdf3874c-c27f-4816-bc8c-046b240e0edd \
          --key-name coreos \
          --flavor m1.medium \
          --num-instances 3
          --security-groups default coreos

    > If you want to run a single instance just omit the `--num-instances` flag.

Your first CoreOS cluster should now be running. The only thing left to do is
find an IP and SSH in.

```
$ nova list
+--------------------------------------+-----------------+--------+------------+-------------+-------------------+
| ID                                   | Name            | Status | Task State | Power State | Networks          |
+--------------------------------------+-----------------+--------+------------+-------------+-------------------+
| a1df1d98-622f-4f3b-adef-cb32f3e2a94d | coreos-a1df1d98 | ACTIVE | None       | Running     | private=10.0.0.3  |
| db13c6a7-a474-40ff-906e-2447cbf89440 | coreos-db13c6a7 | ACTIVE | None       | Running     | private=10.0.0.4  |
| f70b739d-9ad8-4b0b-bb74-4d715205ff0b | coreos-f70b739d | ACTIVE | None       | Running     | private=10.0.0.5  |
+--------------------------------------+-----------------+--------+------------+-------------+-------------------+
```

Finally SSH into an instance, note that the user is `core`:

```
$ chmod 400 core.pem
$ ssh -i core.pem core@10.0.0.3
   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/

core@10-0-0-3 ~ $
```

## Adding More Machines

Adding new instances to the cluster is as easy as launching more with the same 
discovery URL. New instances will join the cluster assuming they can communicate 
with the others.

Example:

        $ nova boot \
          --user-data ./userdata.txt \
          --image cdf3874c-c27f-4816-bc8c-046b240e0edd \
          --key-name coreos \
          --flavor m1.medium \
          --security-groups default coreos

## Multiple Clusters

If you would like to create multiple clusters you'll need to generate and use a
new token. Change the token value on the `ETCD_DISCOVERY_URL` line in the user
data script, and boot new instances.

## Using CoreOS

Now that you have instances booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
