---
layout: docs
slug: openstack
title: Documentation
---

# Running CoreOS on OpenStack

CoreOS is currently in heavy development and actively being tested.  These
instructions will walk you through downloading CoreOS for OpenStack, importing
it with the `glance` tool and running it with the `nova` tool.

## Import the Image

These steps will download the CoreOS image, uncompress it and then import it
into the glance image store.

```
$ wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
$ glance image-create --name CoreOS --container-format ovf --disk-format qcow2 --file coreos_production_openstack_image.img --is-public True
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

## Boot it up

Now generate the ssh key that will be injected into the image for the `core`
user and boot it up!

```
$ nova keypair-add coreos > core.pem
$ nova boot --image cdf3874c-c27f-4816-bc8c-046b240e0edd --key-name coreos --flavor m1.medium --security-groups default coreos
...
```

Your first CoreOS instance should now be running. The only thing left to do is
find the IP and SSH in.

```
$ nova list
+--------------------------------------+--------+--------+------------+-------------+------------------+
| ID                                   | Name   | Status | Task State | Power State | Networks         |
+--------------------------------------+--------+--------+------------+-------------+------------------+
| 85aafe1a-f634-4665-a42b-43e49015a865 | coreos | ACTIVE | None       | Running     | private=10.0.0.3 |
+--------------------------------------+--------+--------+------------+-------------+------------------+
```

Finally SSH into it, note that the user is `core`:

```
$ ssh -i core.pem core@10.0.0.3
   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/

core@10-0-0-3 ~ $
```

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out
the [Using CoreOS][using-coreos] guide.
