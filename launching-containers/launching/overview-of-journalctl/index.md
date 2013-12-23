---
layout: docs
slug: guides
title: Overview of journalctl
category: launching_containers
sub_category: launching
weight: 5
---

# Overview of journalctl

`journalctl` is your interface into systemd's journal/logging. All service files and docker containers insert data into the systemd journal. There are a few helpful commands to read the journal:

## Read the Entire Journal

```
$ journalctl

-- Logs begin at Fri 2013-12-13 23:43:32 UTC, end at Sun 2013-12-22 12:28:45 UTC. --
Dec 22 00:10:21 localhost systemd-journal[33]: Runtime journal is using 184.0K (max 49.9M, leaving 74.8M of free 499.0M, current limit 49.9M).
Dec 22 00:10:21 localhost systemd-journal[33]: Runtime journal is using 188.0K (max 49.9M, leaving 74.8M of free 499.0M, current limit 49.9M).
Dec 22 00:10:21 localhost kernel: Initializing cgroup subsys cpuset
Dec 22 00:10:21 localhost kernel: Initializing cgroup subsys cpu
Dec 22 00:10:21 localhost kernel: Initializing cgroup subsys cpuacct
Dec 22 00:10:21 localhost kernel: Linux version 3.11.7+ (buildbot@10.10.10.10) (gcc version 4.6.3 (Gentoo Hardened 4.6.3 p1.13, pie-0.5.2)
...
1000s more lines
```
## Read Entires for a Specific Service

```
$ journalctl -u apache.service

-- Logs begin at Fri 2013-12-13 23:43:32 UTC, end at Sun 2013-12-22 12:32:52 UTC. --
Dec 22 12:32:39 localhost systemd[1]: Starting Apache Service...
Dec 22 12:32:39 localhost systemd[1]: Started Apache Service.
Dec 22 12:32:39 localhost docker[9772]: /usr/sbin/apache2ctl: 87: ulimit: error setting limit (Operation not permitted)
Dec 22 12:32:39 localhost docker[9772]: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.6 for ServerName
```

## Read Entries Since Boot

Reading just the entires since the last boot is an easy way to troubleshoot services that are faiing to start properly:

```
journalctl --boot
```

## Tail the Journal

You can tail the entire journal or just a specific service:

```
journalctl -f
```

```
journalctl -u apache.service -f
```

#### More Information
<a class="btn btn-default" href="{{site.url}}/docs/launching-containers/launching/getting-started-with-systemd">Getting Started with systemd</a>