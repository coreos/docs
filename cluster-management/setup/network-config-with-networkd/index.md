---
layout: docs
title: Network Configuration
category: cluster_management
sub_category: setting_up
weight: 7
---

# Network Configuration with networkd

CoreOS machines are preconfigured with [networking customized]({{site.url}}/docs/sdk-distributors/distributors/notes-for-distributors) for each platform. You can write your own networkd units to replace or override the units created for each platform. This article covers a subset of networkd functionality. You can view the [full docs here](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).

Drop a file in `/etc/systemd/network/` or inject a file on boot via [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/#write_files) to override an existing file. Let's take a look at two common situations: using a static IP and turning off DHCP.

## Static Networking

To configure a static IP on `enp2s0`, create `static.network`:

```
[Match]
Name=enp2s0

[Network]
Address=192.168.0.15/24
Gateway=192.168.0.1
```

Place the file in `/etc/systemd/network/`. To apply the configuration, run:

```
sudo systemctl restart systemd-networkd
```

## Turn Off DHCP

If you'd like to use DHCP on all interfaces except `enp2s0`, create two files. They'll be checked in lexical order, as described in the [full network docs](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html). Any interfaces matching during earlier files will be ignored during later files.

#### 10-static.network

```
[Match]
Name=enp2s0

[Network]
Address=192.168.0.15/24
Gateway=192.168.0.1
```

Put your settings-of-last-resort in `20-dhcp.network`. For example, any interfaces matching `en*` that weren't matched in `10-static.network` will be configured with DHCP:

#### 20-dhcp.network

```
[Match]
Name=en*

[Network]
DHCP=yes
```

To apply the configuration, run `sudo systemctl restart systemd-networkd`. Check the status with `systemctl status systemd-networkd` and read the full log with `journalctl -u systemd-networkd`.

## Further Reading

If you're interested in more general networkd features, check out the [full documentation](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).