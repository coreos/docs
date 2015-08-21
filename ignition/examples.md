# Example Configs #

Each of these examples is written in version 1 of the config. Always double
check to make sure that your config matches the version that Ignition is
expecting.

## Reformat the Root Filesystem ##

In many scenarios, it may be preferable to use btrfs for the root filesystem.
This config will find the device with the filesystem label "ROOT" (the root
filesystem) and reformat it to btrfs, maintaining the filesystem label. The
force flag is needed here because CoreOS currently ships with an ext4 root
filesystem. Without this flag, Ignition would recognize that there is existing
data and refuse to overwrite it.

```json
{
	"ignitionVersion": 1,
	"storage": {
		"filesystems": [
			{
				"device": "/dev/disk/by-label/ROOT",
				"format": "btrfs",
				"create": {
					"force": true,
					"options": [
						"--label=ROOT"
					]
				}
			}
		]
	}
}
```

## Create a RAID-enabled Data Volume ##

In many scenarios, it may be useful to have an external data volume. This
config will set up a RAID0 btrfs volume, data, between two seperate disks. It
also writes a mount unit (shown below) which will automatically mount the
volume to /var/lib/data on boot.

```json
{
	"ignitionVersion": 1,
	"storage": {
		"disks": [
			{
				"device": "/dev/sdb",
				"wipe-table": true,
				"partitions": [
					{
						"label": "raid.1.1",
						"number": 1,
						"size": 20480,
						"start": 0
					}
				]
			},
			{
				"device": "/dev/sdc",
				"wipe-table": true,
				"partitions": [
					{
						"label": "raid.1.2",
						"number": 1,
						"size": 20480,
						"start": 0
					}
				]
			}
		],
		"raid": [
			{
				"devices": [
					"/dev/disk/by-partlabel/raid.1.1",
					"/dev/disk/by-partlabel/raid.1.2"
				],
				"level": "stripe",
				"name": "data"
			}
		],
		"filesystems": [
			{
				"device": "/dev/md/data",
				"format": "btrfs",
				"create": {
					"options": [
						"--label=DATA"
					]
				}
			}
		]
	},
	"systemd": {
		"units": [
			{
				"name": "var-lib-data.mount",
				"enable": true,
				"contents": "[Mount]\nWhat=/dev/md/data\nWhere=/var/lib/data\nType=btrfs\n\n[Install]\nWantedBy=local-fs.target"
			}
		]
	}
}
```

### var-lib-data.mount ###

```
[Mount]
What=/dev/data
Where=/var/lib/data
Type=btrfs

[Install]
WantedBy=local-fs.target
```

## etcd2 With coreos-metadata ##

This config will write a systemd drop-in (shown below) for etcd2.service. The
drop-in modifies the ExecStart option, adding a few flags to etcd2's
invocation. These flags use variables defined by coreos-metadata.service to
change the interfaces on which etcd2 listens. coreos-metadata is provided by
CoreOS and will read the appropriate metadata for the cloud environment and
write the results to /run/metadata/coreos. For more information on the
supported platforms and environment variables, refer to the [coreos-metadata
README][coreos-metadata]

```json
{
	"ignitionVersion": 1,
	"systemd": {
		"units": [
			{
				"name": "etcd2.service",
				"enable": true,
				"dropins": [
					{
						"name": "metadata.conf",
						"contents": "[Unit]\nRequires=coreos-metadata.service\nAfter=coreos-metadata.service\n\n[Service]\nEnvironmentFile=/run/metadata/coreos\nExecStart=\nExecStart=/usr/bin/etcd2 --advertise-client-urls=http://${COREOS_IPV4_PUBLIC}:2379 --initial-advertise-peer-urls=http://${COREOS_IPV4_LOCAL}:2380 --listen-client-urls=http://0.0.0.0:2379 --listen-peer-urls=http://${COREOS_IPV4_LOCAL}:2380 --initial-cluster=${ETCD_NAME}=http://${COREOS_IPV4_LOCAL}:2380"
					}
				]
			}
		]
	}
}
```

[coreos-metadata]: https://github.com/coreos/coreos-metadata/blob/master/README.md

### metadata.conf ###

```
[Unit]
Requires=coreos-metadata.service
After=coreos-metadata.service

[Service]
EnvironmentFile=/run/metadata/coreos
ExecStart=
ExecStart=/usr/bin/etcd2 \
	--advertise-client-urls=http://${COREOS_IPV4_PUBLIC}:2379 \
	--initial-advertise-peer-urls=http://${COREOS_IPV4_LOCAL}:2380 \
	--listen-client-urls=http://0.0.0.0:2379 \
	--listen-peer-urls=http://${COREOS_IPV4_LOCAL}:2380 \
	--initial-cluster=${ETCD_NAME}=http://${COREOS_IPV4_LOCAL}:2380
```

## Custom Metadata Agent ##

In the event that CoreOS is being used outside of a supported cloud environment
(e.g. PXE booted, bare-metal installation, Mom and Pop Compute),
coreos-metadata won't work. However, it is possible to write a custom metadata
service if needed.


This config will write a single service unit with the contents of a metadata
agent service (shown below). This unit will not start on its own because it is
not enabled and it is not a dependency of any other units. This metadata agent
will fetch instance metadata from EC2 and save it to an ephemeral file.

```json
{
	"ignitionVersion": 1,
	"systemd": {
		"units": [
			{
				"name": "metadata.service",
				"contents": "[Unit]\nDescription=EC2 metadata agent\n\n[Service]\nType=oneshot\nEnvironment=OUTPUT=/run/metadata/ec2\nExecStart=/usr/bin/mkdir --parent /run/metadata\nExecStart=/usr/bin/bash -c 'echo \"COREOS_IPV4_PUBLIC=$(curl --url http://169.254.169.254/2009-04-04/meta-data/public-ipv4 --retry 10)\\nCOREOS_IPV4_LOCAL=$(curl --url http://169.254.169.254/2009-04-04/meta-data/local-ipv4 --retry 10)\" > ${OUTPUT}'\n"
			}
		]
	}
}
```

### metadata.service ###

```
[Unit]
Description=EC2 metadata agent

[Service]
Type=oneshot
Environment=OUTPUT=/run/metadata/ec2
ExecStart=/usr/bin/mkdir --parent /run/metadata
ExecStart=/usr/bin/bash -c 'echo "COREOS_IPV4_PUBLIC=$(curl\
	--url http://169.254.169.254/2009-04-04/meta-data/public-ipv4\
	--retry 10)\nCOREOS_IPV4_LOCAL=$(curl\
	--url http://169.254.169.254/2009-04-04/meta-data/local-ipv4\
	--retry 10)" > ${OUTPUT}'
```
