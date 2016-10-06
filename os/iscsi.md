# iSCSI on CoreOS

CoreOS has integrated support for mounting iSCSI devices. In order to configure it, do the following:

## Configure the CoreOS iSCSI initiator name

iSCSI clients each have a unique initiator name. CoreOS generates a unique
initiator name on each install and stores it in
/etc/iscsi/initiatorname.iscsi. This may be replaced if necessary.

## Configure the global iSCSI credentials

If all iSCSI mounts on a CoreOS system use the same credentials, these may
be configured locally by editing /etc/iscsi/iscsid.conf and setting the
node.session.auth.username and node.session.auth.password fields. If the
iSCSI target is configured to support mutual authentication (allowing the
initiator to verify that it is speaking to the correct client), these should
be set in node.session.auth.username_in and node.session.auth.password_in.

## Start the iSCSI daemon

systemctl start iscsid

## Discover available iSCSI targets

Run

iscsiadm -m discovery -t sendtargets -p target_ip:port

## To provide target-specific credentials

You can replace the global credentials with target-specific credentials by running:

iscsiadm -m node --targetname=targetname --op-update --name=node.session.auth.username --value=username

iscsiadm -m node --targetname=targetname --op-update --name=node.session.auth.password --value=password

## Log into an iSCSI target

iscsiadm -m node --login

will log into all discovered targets. To log into a specific target:

iscsiadm -m node --targetname=targetname --login

## Enable automatic iSCSI login at boot

If you want to connect to iSCSI targets automatically at boot, run

systemctl enable iscsid

## Mounting iSCSI targets

See https://coreos.com/os/docs/latest/mounting-storage.html