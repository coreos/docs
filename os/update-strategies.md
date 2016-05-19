# Reboot strategies on updates

The overarching goal of CoreOS is to secure the Internet's backend infrastructure. We believe that [automatically updating](https://coreos.com/using-coreos/updates/) the operating system is one of the best tools to achieve this goal.

We realize that each CoreOS cluster has a unique tolerance for risk and the operational needs of your applications are complex. In order to meet everyone's needs, there are four update strategies that we have developed based on feedback during our alpha period.

It's important to note that updates are always downloaded to the passive partition when they become available. A reboot is the last step of the update, where the active and passive partitions are swapped ([rollback instructions][rollback]). These strategies control how that reboot occurs:

| Strategy      | Description                                                         |
|---------------|---------------------------------------------------------------------|
| `best-effort` | Default. If etcd is running, `etcd-lock`, otherwise simply `reboot` |
| `etcd-lock`   | Reboot after first taking a distributed lock in etcd                |
| `reboot`      | Reboot immediately after an update is applied                       |
| `off`         | Do not reboot after updates are applied                             |

## Reboot strategy options

The reboot strategy is defined in [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md#update):

```yaml
#cloud-config
coreos:
  update:
    reboot-strategy: best-effort
```

### Best effort

The default setting is for CoreOS to make a `best-effort` to determine if the machine is part of a cluster. Currently this logic is very simple: if etcd has started, assume that the machine is part of a cluster and use the `etcd-lock` strategy.

Otherwise, use the `reboot` strategy.

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

PXE/iPXE machines download a new copy of CoreOS every time they are started thus are dependent on the version of CoreOS they are served. If you don't automatically load new CoreOS images into your PXE/iPXE server, your machines will never have new features or security updates.

An easy solution to this problem is to use iPXE and reference images [directly from the CoreOS storage site](booting-with-ipxe.md#setting-up-ipxe-boot-script). The `alpha` URL is automatically pointed to the new version of CoreOS as it is released.

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

Public Internet access is required to contact CoreUpdate and download new versions of CoreOS. If direct access is not available the `update-engine` service may be configured to use a HTTP or SOCKS proxy using curl-compatible environment variables, such as `HTTPS_PROXY` or `ALL_PROXY`.
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

## Manually triggering an update

Each machine should check in about 10 minutes after boot and roughly every hour after that. If you'd like to see it sooner, you can force an update check, which will skip any rate-limiting settings that are configured in CoreUpdate.

```
$ update_engine_client -check_for_update
[0123/220706:INFO:update_engine_client.cc(245)] Initiating update check and install.
```

### Running Manual Update with update-engine disabled

If you disabled update-engine.service and wish to run the manual update, you must first enable the update-service to run the update_engine_client:

```
$ systemctl start update-engine.service
$ update_engine_client -check_for_update
```

After the update you must comment out or remove the disabling of the update-engine.service for this first reboot. This allows for the update-engine to mark the new active partition, being your updated one, as a successful boot. If you do not run update-engine upon the first reboot, there is a chance that your machine will mark the new active partition as a failure and revert back to the passive partition (being the previous version) on the next reboot of the machine. Once rebooted you are able to again stop the update-engine and uncomment or add the update-engine.service disabling in your cloud-config.yml.

To avoid this process, a potential option is to use a Service for disabling update-engine and locksmithd using the [Systemd OnCalendar setting](oncalendar-option) which will disable the update-engine.service and locksmithd.service in a particular time period after reboot.

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
[oncalendar-option]:  https://coreos.com/os/docs/latest/scheduling-tasks-with-systemd-timers.html
