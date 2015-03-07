---
layout: docs
slug: guides
title: Working with btrfs
category: cluster_management
sub_category: debugging
weight: 5
---

# Working with btrfs and Common Troubleshooting

btrfs is a copy-on-write filesystem with full support in the upstream Linux kernel, which is important since CoreOS frequently ships [updated versions]({{site.url}}/releases) of the kernel. Docker has a storage driver for btrfs and it is set up on CoreOS out of the box.

btrfs was marked as experimental for a long time, but it's now fully production-ready and supported by a number of Linux distributions.

Notable Features of btrfs:

 - Ability to add/remove block devices without interruption
 - Ability to balance the filesystem without interruption
 - RAID 0, RAID 1, RAID 5, RAID 6 and RAID 10
 - Snapshots and file cloning

This guide won't cover these topics &mdash; it's mostly focused on troubleshooting.

For a more complete troubleshooting experience, let's explore how btrfs works under the hood.

btrfs stores data in chunks across all of the block devices on the system. The total storage across these devices is shown in the standard output of `df -h`.

Raw data and filesystem metadata are stored in one or many chunks, typically ~1GiB in size. When RAID is configured, these chunks are replicated instead of individual files.

A copy-on-write filesystem maintains many changes of a single file, which is helpful for snapshotting and other advanced features, but can lead to fragmentation with some workloads.

## No Space Left on Device

When the filesystem is out of chunks to write data into, `No space left on device` will be reported. This will prevent journal files from being recorded, containers from starting and so on.

The common reaction to this error is to run `df -h` and you'll see that there is still some free space. That command isn't measuring the btrfs primitives (chunks, metadata, etc), which is what really matters.

Running `sudo btrfs fi show` will give you the btrfs view of how much free space you have. When starting/stopping many docker containers or doing a large amount of random writes, chunks will become duplicated in an inefficient manner over time.

Re-balancing the filesystem ([official btrfs docs](https://btrfs.wiki.kernel.org/index.php/Balance_Filters)) will relocate data from empty or near-empty chunks to free up space. This operation can be done without downtime.

First, let's see how much free space we have:

```sh
$ sudo btrfs fi show
Label: 'ROOT'  uuid: 82a40c46-557e-4848-ad4d-10c6e36ed5ad
  Total devices 1 FS bytes used 13.44GiB
  devid    1 size 32.68GiB used 32.68GiB path /dev/xvda9

Btrfs v3.14_pre20140414
```

The answer: not a lot. We can re-balance to fix that.

The re-balance command can be configured to only relocate data in chunks up to a certain percentage used. This will prevent you from moving around a lot of data without a lot of benefit. If your disk is completely full, you may need to delete a few containers to create space for the re-balance operation to work with.

Let's try to relocate chunks with less than 5% of usage:

```sh
$ sudo btrfs fi balance start -dusage=5 /
Done, had to relocate 5 out of 45 chunks
$ sudo btrfs fi show
Label: 'ROOT'  uuid: 82a40c46-557e-4848-ad4d-10c6e36ed5ad
  Total devices 1 FS bytes used 13.39GiB
  devid    1 size 32.68GiB used 28.93GiB path /dev/xvda9

Btrfs v3.14_pre20140414
```

The operation took about a minute on a cloud server and gained us 4GiB of space on the filesystem. It's up to you to find out what percentage works best for your workload, the speed of your disks, etc.

If your balance operation is taking a long time, you can open a new shell and find the status:

```
$ sudo btrfs balance status /
Balance on '/' is running
0 out of about 1 chunks balanced (1 considered), 100% left
```

## Adding a New Physical Disk

New physical disks can be added to an existing btrfs filesystem. The first step is to have the new block device [mounted on the machine]({{site.url}}/docs/cluster-management/setup/mounting-storage/). Afterwards, let btrfs know about the new device and re-balance the file system. The key step here is re-balancing, which will move the data and metadata across both block devices. Expect this process to take some time:

```sh
$ btrfs device add /dev/sdc /
$ btrfs filesystem balance /
```

## Disable Copy-On-Write

Copy-On-write isn't ideal for workloads that create or modify many small files, such as databases. Without disabling COW, you can heavily fragment the file system as explained above.

The best strategy for successfully running a database in a container is to disable COW on directory/volume that is mounted into the container. 

The COW setting is stored as a file attribute and is modified with a utility called `chattr`. To disable COW for a MySQL container's volume, run:

```sh
$ sudo mkdir /var/lib/mysql
$ sudo chattr -R +C /var/lib/mysql
```

The directory `/var/lib/mysql` is now ready to be used by a docker container without COW. Let's break down the command:

`-R` indicates that want to recursively change the file attribute
`+C` means we want to set the NOCOW attribute on the file/directory

To verify, we can run:

```sh
$ sudo lsattr /var/lib/     
---------------- /var/lib/portage
---------------- /var/lib/gentoo
---------------- /var/lib/iptables
---------------- /var/lib/ip6tables
---------------- /var/lib/arpd
---------------- /var/lib/ipset
---------------- /var/lib/dbus
---------------- /var/lib/systemd
---------------- /var/lib/polkit-1
---------------- /var/lib/dhcpcd
---------------- /var/lib/ntp
---------------- /var/lib/nfs
---------------- /var/lib/etcd
---------------- /var/lib/docker
---------------- /var/lib/update_engine
---------------C /var/lib/mysql
```

### Disable in a Unit File

Setting the file attributes can be done within a systemd unit using two `ExecStartPre` commands:

```ini
ExecStartPre=/usr/bin/mkdir -p /var/lib/mysql
ExecStartPre=/usr/bin/chattr -R +C /var/lib/mysql
```
