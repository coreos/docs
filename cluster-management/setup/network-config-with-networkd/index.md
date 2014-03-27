---
layout: docs
title: Network Configuration
category: cluster_management
sub_category: setting_up
weight: 7
---

<div class="coreos-docs-banner">
<span class="glyphicon glyphicon-info-sign"></span>These features are only available on <a href="{{site.url}}/blog/new-images-with-cloud-config/">our new images</a>. Currently EC2, GCE, Vagrant and Openstack have networkd support.
</div>

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

If you'd like to use DHCP on all interfaces except `enp2s0`, create two files that run in order of least specificity. Configure general settings in `10-dhcp.network`:

```
[Match]
Name=en*

[Network]
DHCP=yes
```

Write your static configuration in `20-static.network`:

```
[Match]
Name=enp2s0

[Network]
Address=192.168.0.15/24
Gateway=192.168.0.1
```

To apply the configuration, run `sudo systemctl restart systemd-networkd`.

## Further Reading

If you're interested in more general networkd features, check out the [full documentation](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).