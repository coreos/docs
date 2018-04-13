# Switching release channels

Container Linux is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

By design, the Container Linux update engine does not execute downgrades. If you're switching from a channel with a higher Container Linux version than the new channel, your machine won't be updated again until the new channel contains a higher version number.

![Update Timeline](img/update-timeline.png)

## Customizing channel configuration

The update engine sources its configuration from `/usr/share/coreos/update.conf` and `/etc/coreos/update.conf`.
The former file contains the default hardcoded configuration from the running OS version. Its values cannot be edited, but they can be overridden by the ones in the latter file.

To switch a machine to a different channel, specify the new channel group in `/etc/coreos/update.conf`:

```ini
GROUP=beta
```

In order for the configuration override to take effect, the update engine must first be restarted:

```sh
sudo systemctl restart update-engine
```

## Debugging

After the update engine is restarted, the machine should check for an update within an hour.

The live status of updates checking can queried via:

```sh
update_engine_client --status
```

The update engine logs all update attempts, which can inspected in the system journal:

```sh
journalctl -f -u update-engine
```

For reference, the OS version and channel for a running system can be determined via:

```sh
cat /usr/share/coreos/os-release

cat /usr/share/coreos/update.conf
```

Note: while a manual channel switch is in progress, `/usr/share/coreos/update.conf` shows the channel for the current OS while `/etc/coreos/update.conf` shows the one for the next update.
