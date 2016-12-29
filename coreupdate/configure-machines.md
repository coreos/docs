# Configure machines to use CoreUpdate

Configuring new or existing Container Linux machines to communicate with a [CoreUpdate](https://coreos.com/products/coreupdate) instance is a simple change to a configuration file.

## New machines

New servers can be configured to communicate with your CoreUpdate installation by using [cloud-config](https://coreos.com/docs/cluster-management/setup/cloudinit-cloud-config).

By default, your installation has a single application, Container Linux, with the identifier `e96281a6-d1af-4bde-9a0a-97b76e56dc57`. This ID is universal and all Container Linux machines are configured to use it. Within the Container Linux application, there are several application groups which have been created to match Container Linux channels with the indentifiers `alpha`, `beta`, and `stable`.

In addition to the default groups, you may choose to create your own group that is configured to use a specific channel, rate-limit and other settings. Groups that you create will have a unique identifier that is a generated UUID or you may provide a custom string.

To place a Container Linux machine in one of these groups, you must configure the update settings via cloud-config or a file on disk.

### Join preconfigured group

Set the value of `server` to the custom address of your installation and append "/v1/update/". Set `group` to one of the default application groups: `alpha`, `beta`, or `stable`.

For example, here is what the Alpha group looks like in CoreUpdate:

![CoreUpdate Group](img/coreupdate-group-default.png)

Here's the cloud-config to use:

```yaml
#cloud-config

coreos:
  update:
    group: alpha
    server: https://customer.update.core-os.net/v1/update/
```

Or the Ignition config:

```json
{
  "ignition": { "version": "2.0.0" },
  "files": [{
    "filesystem": "root",
    "path": "/etc/coreos/update.conf",
    "mode": 420,
    "contents": { "source": "data:,GROUP%3Dalpha%0ASERVER%3Dhttps%3A%2F%2Fcustomer.update.core-os.net%2Fv1%2Fupdate%2F" }
  }]
}
```

### Join custom group

Set the value of `server` to the custom address of your installation and append "/v1/update/". Set `group` to the unique identifier of your application group.

For example, here is what "NYC Production" looks like in CoreUpdate:

![CoreUpdate Group](img/coreupdate-group.png)

Here's the cloud-config to use:

```yaml
#cloud-config

coreos:
  update:
    group: 0a809ab1-c01c-4a6b-8ac8-6b17cb9bae09
    server: https://customer.update.core-os.net/v1/update/
```

More information can be found in the [cloud-config guide](http://coreos.com/docs/cluster-management/setup/cloudinit-cloud-config/#coreos).

Or the Ignition config:

```json
{
  "ignition": { "version": "2.0.0" },
  "files": [{
    "filesystem": "root",
    "path": "/etc/coreos/update.conf",
    "mode": 420,
    "contents": { "source": "data:,GROUP%3D0a809ab1-c01c-4a6b-8ac8-6b17cb9bae09%0ASERVER%3Dhttps%3A%2F%2Fcustomer.update.core-os.net%2Fv1%2Fupdate%2F" }
  }]
}
```

## Existing machines

To change the update of existing machines, edit `/etc/coreos/update.conf` with your favorite editor and provide the `SERVER=` and `GROUP=` values:

```
GROUP=0a809ab1-c01c-4a6b-8ac8-6b17cb9bae09
SERVER=https://customer.update.core-os.net/v1/update/
```

To apply the changes, run:

```
sudo systemctl restart update-engine
```

In addition to `GROUP=` and `SERVER=`,  a few other internal values exist, but are set to defaults. You shouldn't have to modify these.

`COREOS_RELEASE_APPID`: the Container Linux app ID, `e96281a6-d1af-4bde-9a0a-97b76e56dc57`

`COREOS_RELEASE_VERSION`: defaults to the version of Container Linux you're running

`COREOS_RELEASE_BOARD`: defaults to `amd64-usr`

## Viewing machines in CoreUpdate

Each machine should check in about 10 minutes after boot and roughly every hour after that. If you'd like to see it sooner, you can force an update check, which will skip any rate-limiting settings that are configured.

### Force update in background

```
$ update_engine_client -check_for_update
[0123/220706:INFO:update_engine_client.cc(245)] Initiating update check and install.
```

### Force update in foreground

If you want to see what's going on behind the scenes, you can watch the ouput in the foreground:

```
$ update_engine_client -update
[0123/222449:INFO:update_engine_client.cc(245)] Initiating update check and install.
[0123/222449:INFO:update_engine_client.cc(250)] Waiting for update to complete.
LAST_CHECKED_TIME=0
PROGRESS=0.000000
CURRENT_OP=UPDATE_STATUS_IDLE
NEW_VERSION=0.0.0.0
NEW_SIZE=0
[0123/222454:ERROR:update_engine_client.cc(189)] Update failed.
```

Be aware that the "failed update" means that there isn't a newer version to install.
