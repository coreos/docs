---
layout: docs
slug: guides
title: Prevent Reboot After Update
category: cluster_management
sub_category: debugging
weight: 8
---

# Prevent Reboot After Update

This is a temporary workaround to disable auto updates. As we move out of the alpha there will be a nicer method.

There is a single simple script called `update-engine-reboot-manager` that does an automatic reboot after update-engine applies an update to your CoreOS machine. To stop automatic reboots after an update has been applied you need to stop this daemon.

## Stop Reboots on a Single Machine

```
sudo systemctl stop update-engine-reboot-manager.service
sudo systemctl mask update-engine-reboot-manager.service
```

## Stop Update Reboots with Cloud-Config

You can use [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config) to run these commands on newly booted machines:

```
#cloud-config

coreos:
    units:
      - name: stop-reboot-manager.service
        content: |
          [Unit]
          Description=stop update-engine-reboot-manager

          [Service]
          Type=oneshot
          ExecStart=/usr/bin/systemctl stop update-engine-reboot-manager.service
          ExecStartPost=/usr/bin/systemctl mask update-engine-reboot-manager.service

          [Install]
          WantedBy=multi-user.target
```

## Applying New Updates

You can decide to update at any time by rebooting your machine.

## Restart Update Reboots

```
sudo systemctl unmask update-engine-reboot-manager.service
sudo systemctl start update-engine-reboot-manager.service
```

Have fun!
