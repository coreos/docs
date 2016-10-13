# iSCSI on CoreOS

[iSCSI][iscsi-wiki] is a protocol which provides block-level access to storage devices over IP.
This allows applications to treat remote storage devices as if they were local disks.
iSCSI handles taking requests from clients and carrying them out on the remote SCSI devices.

CoreOS has integrated support for mounting devices.
This guide covers iSCSI configuration manually or automatically with either cloud-config or Ignition.

## Manual iSCSI configuration

### Set the CoreOS iSCSI initiator name

iSCSI clients each have a unique initiator name.
CoreOS generates a unique initiator name on each install and stores it in `/etc/iscsi/initiatorname.iscsi`.
This may be replaced if necessary.

### Configure the global iSCSI credentials

If all iSCSI mounts on a CoreOS system use the same credentials, these may be configured locally by editing `/etc/iscsi/iscsid.conf` and setting the `node.session.auth.username` and `node.session.auth.password` fields.
If the iSCSI target is configured to support mutual authentication (allowing the initiator to verify that it is speaking to the correct client), these should be set in `node.session.auth.username_in` and `node.session.auth.password_in`.

### Start the iSCSI daemon

```
systemctl start iscsid
```

### Discover available iSCSI targets

To discover targets, run:

```
$ iscsiadm -m discovery -t sendtargets -p target_ip:target_port
```

### Provide target-specific credentials

For each unique `--targetname`, first enter the username:

```
$ iscsiadm -m node \
  --targetname=custom_target \
  --op update \
  --name=node.session.auth.username \
  --value=my_username
```

And then the password:

```
$ iscsiadm -m node \
  --targetname=custom_target \
  --op update \
  --name=node.session.auth.password \
  --value=my_secret_passphrase
```

### Log into an iSCSI target

The following command will log into all discovered targets.

```
$ iscsiadm -m node --login
```

Then, to log into a specific target use:

```
$ iscsiadm -m node --targetname=custom_target --login
```

### Enable automatic iSCSI login at boot

If you want to connect to iSCSI targets automatically at boot you first need to enable the systemd service:

```
$ systemctl enable iscsid
```

## Automatic iSCSI configuration

To configure and start iSCSI automatically after a machine is provisioned, credentials need to be written to disk and the iSCSI service started.

Both cloud-config and Ignition will write the file `/etc/iscsi/iscsid.conf` to disk:

#### /etc/iscsi/iscsid.conf
<!-- TODO: It's inclear based on documentation what the actual first line of this doc snippet should be.
     This is a best guess based on docs I've read, the rest I'm pretty certain of.
     I know we want to do discovery in this file, just not sure if that line accomplished the task. -->
     
```
isns.address = host_ip
isns.port = host_port
node.session.auth.username = my_username
node.session.auth.password = my_secret_password
discovery.sendtargets.auth.username = my_username
discovery.sendtargets.auth.password = my_secret_password
```

Below are two complete configs.

### Using cloud-config

```
#cloud-config
coreos:
    units:
        - name: "iscsid.service"
          command: "start"
write_files:
  - path: "/etc/iscsi/iscsid.conf"
    permissions: "0644"
    owner: "root"
    content: |
      isns.address = host_ip
      isns.port = host_port
      node.session.auth.username = my_username
      node.session.auth.password = my_secret_password
      discovery.sendtargets.auth.username = my_username
      discovery.sendtargets.auth.password = my_secret_password
```

### Using Ignition

Ignition uses the data URI scheme to [write out file contents](https://coreos.com/ignition/docs/latest/examples.html#create-files-on-the-root-filesystem). The generated string is the same as the config in the cloud-config above.

```
{
  "ignition": { "version": "2.0.0" },
  "systemd": {
    "units": [{
      "name": "iscsid.service",
      "enable": true
    }]
  },
  "storage": {
    "files": [{
      "filesystem": "root",
      "path": "/etc/iscsi/iscsid.conf",
      "contents": { "source": "data:text/plain;charset=utf-8;base64,aXNucy5hZGRyZXNzID0gaG9zdF9pcA0KaXNucy5wb3J0ID0gaG9zdF9wb3J0DQpub2RlLnNlc3Npb24uYXV0aC51c2VybmFtZSA9IG15X3VzZXJuYW1lDQpub2RlLnNlc3Npb24uYXV0aC5wYXNzd29yZCA9IG15X3NlY3JldF9wYXNzd29yZA0KZGlzY292ZXJ5LnNlbmR0YXJnZXRzLmF1dGgudXNlcm5hbWUgPSBteV91c2VybmFtZQ0KZGlzY292ZXJ5LnNlbmR0YXJnZXRzLmF1dGgucGFzc3dvcmQgPSBteV9zZWNyZXRfcGFzc3dvcmQ=" }
    }]
  }
}
```

## Mounting iSCSI targets

See the [mounting storage docs][mounting-storage] for an example.

[iscsi-wiki]: https://en.wikipedia.org/wiki/ISCSI
[mounting-storage]: mounting-storage.md
