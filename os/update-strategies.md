# Reboot strategies on updates

The overarching goal of Container Linux is to secure the Internet's backend infrastructure. We believe that [automatically updating](https://coreos.com/using-coreos/updates/) the operating system is one of the best tools to achieve this goal.

We realize that each Container Linux cluster has a unique tolerance for risk and the operational needs of your applications are complex. In order to meet everyone's needs, there are four update strategies that we have developed based on feedback during our alpha period.

It's important to note that updates are always downloaded to the passive partition when they become available. A reboot is the last step of the update, where the active and passive partitions are swapped ([rollback instructions][rollback]). These strategies control how that reboot occurs:

| Strategy      | Description                                                         |
|---------------|---------------------------------------------------------------------|
| `etcd-lock`   | Reboot after first taking a distributed lock in etcd                |
| `reboot`      | Reboot immediately after an update is applied                       |
| `off`         | Do not reboot after updates are applied                             |

## Reboot strategy options

The reboot strategy is defined in [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md#update):

```yaml
#cloud-config
coreos:
  update:
    reboot-strategy: etcd-lock
```

### etcd-lock

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

### Reboot immediately

The `reboot` strategy works exactly like it sounds: the machine is rebooted as soon as the update has been installed to the passive partition. If the applications running on your cluster are highly resilient, this strategy was made for you.

### Off

The `off` strategy is also straightforward. The update will be installed onto the passive partition and await a reboot command to complete the update. We don't recommend this strategy unless you reboot frequently as part of your normal operations workflow.

## Updating PXE/iPXE machines

PXE/iPXE machines download a new copy of Container Linux every time they are started thus are dependent on the version of Container Linux they are served. If you don't automatically load new Container Linux images into your PXE/iPXE server, your machines will never have new features or security updates.

An easy solution to this problem is to use iPXE and reference images [directly from the Container Linux storage site](booting-with-ipxe.md#setting-up-ipxe-boot-script). The `alpha` URL is automatically pointed to the new version of Container Linux as it is released.

## Disable Automatic Updates Daemon

In case when you don't want to install updates onto the passive partition and avoid update process on failure reboot, you can disable `update-engine` service manually with `sudo systemctl stop update-engine` command (it will be enabled automatically next reboot).

If you wish to disable automatic updates permanently, use can configure this with Cloud-Config. This example will stop `update-engine`, which executes the updates, and `locksmithd`, which coordinates reboots across the cluster:

```yaml
#cloud-config
coreos:
  units:
    - name: update-engine.service
      command: stop
    - name: locksmithd.service
      command: stop
```

## Updating behind a proxy

Public Internet access is required to contact CoreUpdate and download new versions of Container Linux. If direct access is not available the `update-engine` service may be configured to use a HTTP or SOCKS proxy using curl-compatible environment variables, such as `HTTPS_PROXY` or `ALL_PROXY`.
See [curl's documentation](http://curl.haxx.se/docs/manpage.html#ALLPROXY) for details.

```yaml
#cloud-config

coreos:
  units:
    - name: update-engine.service
      drop-ins:
        - name: 50-proxy.conf
          content: |
            [Service]
            Environment=ALL_PROXY=http://proxy.example.com:3128
      command: restart
```

Proxy environment variables can also be set [system-wide][systemd-env-vars].

## Manually triggering an update

Each machine should check in about 10 minutes after boot and roughly every hour after that. If you'd like to see it sooner, you can force an update check, which will skip any rate-limiting settings that are configured in CoreUpdate.

```
$ update_engine_client -check_for_update
[0123/220706:INFO:update_engine_client.cc(245)] Initiating update check and install.
```

## Auto-updates with a maintenance window

Locksmith supports maintenance windows in addition to the reboot strategies mentioned earlier. Maintenance windows define a window of time during which a reboot can occur. These operate in addition to reboot strategies, so if the machine has a maintenance window and requires a reboot lock, the machine will only reboot when it has the lock during that window.

Windows are defined by a start time and a length. In this example, the window is defined to be every Thursday between 04:00 and 05:00:

```yaml
#cloud-config
coreos:
  locksmith:
    window-start: Thu 04:00
    window-length: 1h
```

For more information about the supported syntax, refer to the [Locksmith documentation][reboot-windows].

[rollback]: manual-rollbacks.md
[reboot-windows]: https://github.com/coreos/locksmith#reboot-windows
[systemd-env-vars]: https://coreos.com/os/docs/latest/using-environment-variables-in-systemd-units.html#system-wide-environment-variables
