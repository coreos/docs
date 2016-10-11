# iSCSI on CoreOS

[iSCSI][iscsi-wiki] is a protocol which provides block-level access to storage devices over IP.  This allows applications to treat remote storage devices as if they were local disks.  iSCSI handles taking requests from clients and carrying them out on the remote SCSI devices.

CoreOS has integrated support for mounting devices. In order to configure it, do the following:

## Configure the CoreOS iSCSI initiator name

iSCSI clients each have a unique initiator name. CoreOS generates a unique initiator name on each install and stores it in `/etc/iscsi/initiatorname.iscsi`. This may be replaced if necessary.

## Configure the global iSCSI credentials

If all iSCSI mounts on a CoreOS system use the same credentials, these may be configured locally by editing `/etc/iscsi/iscsid.conf` and setting the `node.session.auth.username` and `node.session.auth.password` fields. If the iSCSI target is configured to support mutual authentication (allowing the initiator to verify that it is speaking to the correct client), these should be set in `node.session.auth.username_in` and `node.session.auth.password_in`.

## Start the iSCSI daemon

```
systemctl start iscsid
```

## Discover available iSCSI targets

To discover targets, run:

```
$ iscsiadm -m discovery -t sendtargets -p target_ip:port
```

## To provide target-specific credentials

You can replace the global credentials with target-specific credentials by running:

```
$ iscsiadm -m node --targetname=targetname --op-update --name=node.session.auth.username --value=username
$ iscsiadm -m node --targetname=targetname --op-update --name=node.session.auth.password --value=password
```

`targetname`, `username`, and `password` are specific to you, not literal strings. For example:

```
$ iscsiadm -m node --targetname=custom_target --op-update --name=node.session.auth.username --value=some_username
$ iscsiadm -m node --targetname=custom_target --op-update --name=node.session.auth.password --value=secret_password
```

## Log into an iSCSI target

The following command will log into all discovered targets.

```
$ iscsiadm -m node --login
```

Then, to log into a specific target use:

```
$ iscsiadm -m node --targetname=targetname --login
```

The value for `targetname` is unique to your setup. For example:

```
$ iscsiadm -m node --targetname=custom_target --login
```

## Enable automatic iSCSI login at boot

If you want to connect to iSCSI targets automatically at boot, run

```
$ systemctl enable iscsid
```

<!-- TODO: add a cloud-config or ignition example! -->

## Mounting iSCSI targets

See the [mounting storage docs][mounting-storage] for an example.

[iscsi-wiki]: https://en.wikipedia.org/wiki/ISCSI
[mounting-storage]: mounting-storage.md
