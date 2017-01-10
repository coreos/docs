# Switching release channels

Container Linux is released into alpha, beta, and stable channels. New features and bug fixes are tested in the alpha channel and are promoted bit-for-bit to the beta channel if no additional bugs are found.

By design, the Container Linux update engine does not execute downgrades. If you're switching from a channel with a higher Container Linux version than the new channel, your machine won't be updated again until the new channel contains a higher version number.

![Update Timeline](img/update-timeline.png)

## Create update config file

You can switch machines between channels by creating `/etc/coreos/update.conf`:

```ini
GROUP=beta
```

## Restart update engine

The last step is to restart the update engine in order for it to pick up the changed channel:

```sh
sudo systemctl restart update-engine
```

## Debugging

After the update engine is restarted, the machine should check for an update within an hour. You can view the update engine log if you'd like to see the requests that are being made to the update service:

```sh
journalctl -f -u update-engine
```

For reference, you can find the current version:

```sh
cat /etc/os-release
```

## Release information

You can read more about the current releases and channels on the [releases page](https://coreos.com/releases).

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/os/switching-channels.md?pixel)]() <!-- END ANALYTICS -->