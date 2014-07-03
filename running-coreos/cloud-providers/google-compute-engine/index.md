---
layout: docs
category: running_coreos
sub_category: cloud_provider
supported: true
weight: 3
title: Google Compute Engine
---

# Running CoreOS on Google Compute Engine

Before proceeding, you will need to [install gcutil][gcutil-documentation] and check that your GCE account/project has billing enabled (Settings &rarr; Billing). In each command below, be sure to insert your project name in place of `<project-id>`.

[gce-advanced-os]: http://developers.google.com/compute/docs/transition-v1#customkernelbinaries
[gcutil-documentation]: https://developers.google.com/compute/docs/gcutil/

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config). Cloud-config is intended to bring up a cluster of machines into a minimal useful state and ideally shouldn't be used to configure anything that isn't standard across many hosts. On GCE, the cloud-config can be modified while the instance is running and will be processed next time the machine boots.

You can provide cloud-config to CoreOS via the Google Cloud console's metadata field `user-data` or via a flag using `gcutil`.

The most common cloud-config for GCE looks like:

```yaml
#cloud-config

coreos:
  etcd:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    addr: $private_ipv4:4001
    peer-addr: $private_ipv4:7001
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
```

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on GCE.

## Choosing a Channel

CoreOS is designed to be [updated automatically]({{site.url}}/using-coreos/updates) with different schedules per channel. You can [disable this feature]({{site.url}}/docs/cluster-management/debugging/prevent-reboot-after-update), although we don't recommend it. Read the [release notes]({{site.url}}/releases) for specific features and bug fixes.

Create 3 instances from the image above using our cloud-config from `cloud-config.yaml`:

<div id="gce-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.url}}/using-coreos/docker">docker</a>, <a href="{{site.url}}/using-coreos/etcd">etcd</a> and <a href="{{site.url}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
      <pre>gcutil --project=&lt;project-id&gt; addinstance --image={{site.data.alpha-channel.gce-image-path}} --persistent_boot_disk --zone=us-central1-a --machine_type=n1-standard-1 --metadata_from_file=user-data:cloud-config.yaml core1 core2 core3</pre>
    </div>
    <div class="tab-pane active" id="beta-create">
      <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
      <pre>gcutil --project=&lt;project-id&gt; addinstance --image={{site.data.beta-channel.gce-image-path}} --persistent_boot_disk --zone=us-central1-a --machine_type=n1-standard-1 --metadata_from_file=user-data:cloud-config.yaml core1 core2 core3</pre>
    </div>
  </div>
</div>

### Additional Storage

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

For more information about mounting storage, Google's [own documentation](https://developers.google.com/compute/docs/disks#attach_disk) is the best source. You can also read about [mounting storage on CoreOS]({{site.url}}/docs/cluster-management/setup/mounting-storage).

### Adding More Machines
To add more instances to the cluster, just launch more with the same cloud-config inside of the project.

## SSH

You can log in your CoreOS instances using:

```sh
gcutil --project=<project-id> ssh --ssh_user=core <instance-name>
```

## Modify Existing Cloud-Config

To modify an existing instance's cloud-config, read the `metadata-fingerprint` and provide it to the `setinstancemetadata` command along with your new `cloud-config.yaml`:

```sh
$ gcutil --project=coreos-gce-testing getinstance core2

INFO: Zone for core2 detected as us-central1-a.
+------------------------+-----------------------------------------------------+
| name                   | core2                                               |
| description            |                                                     |
| creation-time          | 2014-03-21T14:08:41.516-07:00                       |
| machine                | us-central1-a/machineTypes/n1-standard-1            |
| image                  |                                                     |
| kernel                 |                                                     |
| zone                   | us-central1-a                                       |
| tags-fingerprint       | 42WmSpB8rSM=                                        |
| metadata-fingerprint   | tgFMD53d3kI=                                        |
| status                 | RUNNING                                             |
| status-message         |                                                     |
| on-host-maintenance    | MIGRATE                                             |
| automatic-restart      | True                                                |
| disk                   |                                                     |
|   type                 | PERSISTENT                                          |
|   mode                 | READ_WRITE                                          |
|   device-name          | philips-prod2                                       |
|   source               | https://www.googleapis.com/compute/v1/projects      |
|                        | /coreos-gce-testing/zones/us-central1-a/disks       |
|                        | /core2                                              |
|   boot                 | True                                                |
|   autoDelete           | False                                               |
| network-interface      |                                                     |
|   network              | https://www.googleapis.com/compute/v1/projects      |
|                        | /coreos-gce-testing/global/networks/default         |
|   ip                   | 10.240.191.156                                      |
|   access-configuration | External NAT                                        |
|   type                 | ONE_TO_ONE_NAT                                      |
|   external-ip          | 23.251.151.111                                      |
| metadata               |                                                     |
|   user-data            | #cloud-config\n\ncoreos:\n  etcd:\n      discovery: |
|                        | https://discovery.etcd.io/722abac4b8f737b6e45295894 |
|                        | 8e212af\n      addr: $public_ipv4:4001\n      peer- |
|                        | addr: $private_ipv4:7001\n  units:\n    - name:     |
|                        | etcd.service\n      command: start\n    - name:     |
|                        | fleet.service\n      runtime: yes\n      content:   |
|                        | |\n        [Unit]\n        Description=fleet\n\n    |
|                        | [Service]\n                                         |
|                        | Environment=FLEET_PUBLIC_IP=$public_ipv4\n          |
|                        | ExecStart=/usr/bin/fleet\n                          |
| metadata-fingerprint   | tgFMD53d3kI=                                        |
+------------------------+-----------------------------------------------------+
```

```sh
gcutil --project=<project-id> setinstancemetadata core2 --metadata_from_file=user-data:cloud-config.yaml --fingerprint="tgFMD53d3kI="
```

The new metadata will be applied to the machine after a reboot.

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
