---
layout: docs
slug: openstack
title: Documentation
---

# Running CoreOS on OpenStack

CoreOS is currently in heavy development and actively being tested.
These instructions will walk you through downloading CoreOS for OpenStack.

## Download the Image

The latest production CoreOS OpenStack image can be [found here](http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_openstack_image.img.bz2).

OpenStack is a flexible platform and accurately documenting image installation for
all OpenStack installs is really difficult. If you want to try your hand at it
please [fork this doc][fork-me] and send a pull request.

## Import the Image into OpenStack

```
$ wget http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
```

Quick inspection of the image before importing it:

```
$ qemu-img info coreos_production_openstack_image.img
image: coreos_production_openstack_image.img
file format: qcow2
virtual size: 5.3G (5721032192 bytes)
disk size: 347M
cluster_size: 65536
```

Import it into Glance:

```
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

Create a key:

```
$ nova keypair-add coreos > core.pem
```

Boot the image:

```bash
$ nova boot --image cdf3874c-c27f-4816-bc8c-046b240e0edd --key-name coreos --flavor m1.medium --security-groups default coreos
...
...
```

Get the IP:

```bash
$ nova list
+--------------------------------------+--------+--------+------------+-------------+------------------+
| ID                                   | Name   | Status | Task State | Power State | Networks         |
+--------------------------------------+--------+--------+------------+-------------+------------------+
| 85aafe1a-f634-4665-a42b-43e49015a865 | coreos | ACTIVE | None       | Running     | private=10.0.0.3 |
+--------------------------------------+--------+--------+------------+-------------+------------------+
```

Finally SSH into it, note that the user is `core`:

```bash
$ ssh -i core.pem core@10.0.0.3
   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/

core@10-0-0-3 ~ $
```

[fork-me]: https://github.com/coreos/docs/blob/master/openstack/index.md

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out
the [Using CoreOS][using-coreos] guide.
