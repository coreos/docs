# Running CoreOS on Google Compute Engine

Before proceeding, you will need a GCE account ([get $300 of credit here][free-trial]) and [install gcloud][gcloud-documentation] on your machine. In each command below, be sure to insert your project name in place of `<project-id>`.

[gce-advanced-os]: http://developers.google.com/compute/docs/transition-v1#customkernelbinaries
[gcloud-documentation]: https://cloud.google.com/sdk/
[free-trial]: https://cloud.google.com/free-trial/?utm_source=coreos&utm_medium=partners&utm_campaign=partner-free-trial

After installation, log into your account with `gcloud auth login` and enter your project ID when prompted.

## Cloud-config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md). Cloud-config is intended to bring up a cluster of machines into a minimal useful state and ideally shouldn't be used to configure anything that isn't standard across many hosts. On GCE, the cloud-config can be modified while the instance is running and will be processed next time the machine boots.

You can provide cloud-config to CoreOS via the Google Cloud console's metadata field `user-data` or via a flag using `gcloud`.

The most common cloud-config for GCE looks like:

```yaml
#cloud-config

coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
```

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on GCE.

## Choosing a channel

CoreOS is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

Create 3 instances from the image above using our cloud-config from `cloud-config.yaml`:

<div id="gce-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-alpha --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=cloud-config.yaml</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-beta --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=cloud-config.yaml</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-stable --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=cloud-config.yaml</pre>
    </div>
  </div>
</div>

### Additional storage

Additional disks attached to instances can be mounted with a `.mount` unit. Each disk can be accessed via `/dev/disk/by-id/google-<disk-name>`. Here's the cloud-config to mount a disk called `database-backup`:

```yaml
#cloud-config
coreos:
  units:
    - name: media-backup.mount
      command: start
      content: |
        [Mount]
        What=/dev/disk/by-id/scsi-0Google_PersistentDisk_database-backup
        Where=/media/backup
        Type=ext3
```

For more information about mounting storage, Google's [own documentation](https://developers.google.com/compute/docs/disks#attach_disk) is the best source. You can also read about [mounting storage on CoreOS](mounting-storage.md).

### Adding more machines
To add more instances to the cluster, just launch more with the same cloud-config inside of the project.

## SSH

You can log in your CoreOS instances using:

```sh
gcloud compute ssh --zone us-central1-a core@<instance-name>
```

Users other than `core`, which are set up by the GCE account manager, may not be a member of required groups. If you have issues, try running commands such as `journalctl` with sudo.

## Modify existing cloud-config

To modify an existing instance's cloud-config, use the `add-metadata` command to overwrite the existing data with the new `cloud-config.yaml`:

```sh
gcloud compute instances add-metadata core1 --zone us-central1-a --metadata-from-file=user-data=cloud-config.yaml
```

The new metadata will be applied to the machine after a reboot. To verify that the metadata was set correctly, you can run:

```sh
$ gcloud compute instances describe --zone us-central1-a core1
---
canIpForward: false
creationTimestamp: '2014-07-01T16:04:06.469-07:00'
disks:
- autoDelete: true
  boot: true
  deviceName: persistent-disk-0
  index: 0
  kind: compute#attachedDisk
  mode: READ_WRITE
  source: core1
  type: PERSISTENT
id: '4569192679304736137'
kind: compute#instance
machineType: n1-standard-1
metadata:
  fingerprint: Gi4UKHu-LKk=
  items:
  - key: user-data
    value: "#cloud-config\n\ncoreos:\n  etcd2:\n\
      \    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3\n\
      \    # specify the initial size of your cluster with ?size=X\n\
      \    discovery: https://discovery.etcd.io/<token>\n\
      \    # multi-region and multi-cloud deployments need to use $public_ipv4\n\
      \    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001\n\
      \    initial-advertise-peer-urls: http://$private_ipv4:2380\n\
      \    # listen on both the official ports and the legacy ports\n\
      \    # legacy ports can be omitted if your application doesn't depend on them\n\
      \    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001\n\
      \    listen-peer-urls: http://$private_ipv4:2380\n\
      \  units:\n\
      \    - name: etcd2.service\n      command: start\n    - name: fleet.service\n\
      \      command: start\n"
  kind: compute#metadata
name: rob1
networkInterfaces:
- accessConfigs:
  - kind: compute#accessConfig
    name: external-nat
    natIP: 173.255.112.17
    type: ONE_TO_ONE_NAT
  name: nic0
  network: default
  networkIP: 10.240.95.60
scheduling:
  automaticRestart: true
  onHostMaintenance: MIGRATE
selfLink: https://www.googleapis.com/compute/v1/projects/<project-id>/zones/us-central1-a/instances/core1
serviceAccounts:
- email: 1053319219775@project.gserviceaccount.com
  scopes:
  - https://www.googleapis.com/auth/devstorage.read_only
status: RUNNING
tags:
  fingerprint: 42B8rWmSpSM=
zone: us-central1-a
```

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out the [CoreOS Quickstart](quickstart.md) guide or dig into [more specific topics](https://coreos.com/docs).
