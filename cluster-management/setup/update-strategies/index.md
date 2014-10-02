---
layout: docs
title: Update Strategies
category: cluster_management
sub_category: planning
weight: 7
---

# Update Strategies

The overarching goal of CoreOS is to secure the internet's backend infrastructure. We believe that [automatically updating]({{site.url}}/using-coreos/updates) the operating system is one of the best tools to achieve this goal.

We realize that each CoreOS cluster has a unique tolerance for risk and the operational needs of your applications are complex. In order to meet everyone's needs, there are four update strategies that we have developed based on feedback during our alpha period.

It's important to note that updates are always downloaded to the passive partition when they become available. A reboot is the last step of the update, where the active and passive partitions are swapped. These strategies control how that reboot occurs:

| Strategy           | Description |
|--------------------|-------------|
| `best-effort`        | Default. If etcd is running, `etcd-lock`, otherwise simply `reboot`. |
| `etcd-lock`          | Reboot after first taking a distributed lock in etcd. |
| `reboot`             | Reboot immediately after an update is applied. |
| `off`                | Do not reboot after updates are applied. |

## Strategy Options

The update strategy is defined in [cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/#coreos):

```yaml
#cloud-config
coreos:
  update:
    reboot-strategy: best-effort
```

### Best Effort

The default setting is for CoreOS to make a `best-effort` to determine if the machine is part of a cluster. Currently this logic is very simple: if etcd has started, assume that the machine is part of a cluster and use the `etcd-lock` strategy.

Otherwise, use the `reboot` strategy.

### etcd-Lock

The `etcd-lock` strategy mandates that each machine acquire and hold a reboot lock before it is allowed to reboot. The main goal behind this strategy is to allow for an update to be applied to a cluster quickly, without losing the quorum membership in etcd or rapidly reducing capacity for the services running on the cluster. The reboot lock is held until the machine releases it after a successful update.

The number of machines allowed to reboot simultaneously is configurable via a command line utility:

```sh
$ locksmithctl set-max 4
Old: 1
New: 4
```

This setting is stored in etcd so it won't have to be configured for subsequent machines.

To view the number of available slots and find out which machines in the cluster are holding locks, run:

```sh
$ locksmithctl status
Available: 0
Max: 1

MACHINE ID
69d27b356a94476da859461d3a3bc6fd
```

If needed, you can manually clear a lock by providing the machine ID:

```sh
locksmithctl unlock 69d27b356a94476da859461d3a3bc6fd
```

### Reboot Immediately

The `reboot` strategy works exactly like it sounds: the machine is rebooted as soon as the update has been installed to the passive partition. If the applications running on your cluster are highly resilient, this strategy was made for you.

### Off

The `off` strategy is also straightforward. The update will be installed onto the passive partion and await a reboot command to complete the update. We don't recommend this strategy unless you reboot frequently as part of your normal operations workflow.

## Updating PXE/iPXE Machines

PXE/iPXE machines download a new copy of CoreOS every time they are started thus are dependent on the version of CoreOS they are served. If you don't automatically load new CoreOS images into your PXE/iPXE server, your machines will never have new features or security updates.

An easy solution to this problem is to use iPXE and reference images [directly from the CoreOS storage site]({{site.url}}/docs/running-coreos/bare-metal/booting-with-ipxe/#setting-up-the-boot-script). The `alpha` URL is automatically pointed to the new version of CoreOS as it is released.

## Updating Behind a Proxy

Public Internet access is required to contact CoreUpdate and download new versions of CoreOS.
If direct access is not available the `update-engine` service may be configured to use a HTTP or SOCKS proxy using curl-compatible environment variables, such as `HTTPS_PROXY` or `ALL_PROXY`.
See [curl's documentation](http://curl.haxx.se/docs/manpage.html#ALLPROXY) for details.

```yaml
#cloud-config
write_files:
  - path: /etc/systemd/system/update-engine.service.d/proxy.conf
    content: |
        [Service]
        Environment=ALL_PROXY=http://proxy.example.com:3128
coreos:
    units:
      - name: update-engine.service
        command: restart
```
