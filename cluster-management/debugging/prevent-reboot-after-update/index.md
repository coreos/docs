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

## Create Unit File

There is a single simple script called "update-engine-reboot-manager" that does an automatic reboot after update-engine applies an update to your CoreOS machine. To stop automatic reboots after an update has been applied you need to stop this daemon. You can do this via a service file that is started at boot.

Create a file called `/media/state/units/stop-reboot-manager.service` that has the following contents:

```
[Unit]
Description=stop update-engine-reboot-manager

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl stop update-engine-reboot-manager

[Install]
WantedBy=local.target
```

## Enable It Immediately

```
sudo systemctl enable --runtime /media/state/units/stop-reboot-manager.service
sudo systemctl start stop-reboot-manager.service
```

## Applying New Updates

You can decide to update at any time by rebooting your machine.

Have fun!