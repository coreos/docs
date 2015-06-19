---
layout: docs
title: OpenStack
category: running_coreos
sub_category: platforms
supported: true
weight: 5
---

# Running CoreOS on OpenStack

CoreOS is currently in heavy development and actively being tested.  These
instructions will walk you through downloading CoreOS for OpenStack, importing
it with the `glance` tool and running your first cluster with the `nova` tool.

## Import the Image

These steps will download the CoreOS image, uncompress it and then import it
into the glance image store.

## Choosing a Channel

CoreOS is designed to be [updated automatically]({{site.baseurl}}/using-coreos/updates) with different schedules per channel. You can [disable this feature]({{site.baseurl}}/docs/cluster-management/debugging/prevent-reboot-after-update), although we don't recommend it. Read the [release notes]({{site.baseurl}}/releases) for specific features and bug fixes.

<div id="openstack-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.baseurl}}/using-coreos/docker">docker</a>, <a href="{{site.baseurl}}/using-coreos/etcd">etcd</a> and <a href="{{site.baseurl}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
<pre>
$ wget http://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
<pre>
$ wget http://beta.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
</pre>
    </div>
  <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted. Current version is CoreOS {{site.stable-channel}}.</p>
<pre>
$ wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
</pre>
    </div>
  </div>
</div>

Once the download completes, add the CoreOS image into Glance:

```sh
$ glance image-create --name CoreOS \
  --container-format bare \
  --disk-format qcow2 \
  --file coreos_production_openstack_image.img \
  --is-public True
+------------------+--------------------------------------+
| Property         | Value                                |
+------------------+--------------------------------------+
| checksum         | 4742f3c30bd2dcbaf3990ac338bd8e8c     |
| container_format | ovf                                  |
| created_at       | 2013-08-29T22:21:22                  |
| deleted          | False                                |
| deleted_at       | None                                 |
| disk_format      | qcow2                                |
| id               | cdf3874c-c27f-4816-bc8c-046b240e0edd |
| is_public        | True                                 |
| min_disk         | 0                                    |
| min_ram          | 0                                    |
| name             | coreos                               |
| owner            | 8e662c811b184482adaa34c89a9c33ae     |
| protected        | False                                |
| size             | 363660800                            |
| status           | active                               |
| updated_at       | 2013-08-29T22:22:04                  |
+------------------+--------------------------------------+
```

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config].
We're going to provide our cloud-config to OpenStack via the user-data flag. Our cloud-config will also contain SSH keys that will be used to connect to the instance.
In order for this to work your OpenStack cloud provider must support [config drive][config-drive] or the OpenStack metadata service.

[cloud-config]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config
[config-drive]: http://docs.openstack.org/user-guide/cli_config_drive.html

The most common cloud-config for OpenStack looks like:

```yaml
#cloud-config

coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380,http://$private_ipv4:7001
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380,http://$private_ipv4:7001
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
ssh_authorized_keys:
  # include one or more SSH public keys
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h...
```

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on most OpenStack deployments. Unfortunately some systems relying on config drive may leave these values undefined.

## Launch Cluster

Boot the machines with the `nova` CLI, referencing the image ID from the import step above and your `cloud-config.yaml`:

```sh
nova boot \
--user-data ./cloud-config.yaml \
--image cdf3874c-c27f-4816-bc8c-046b240e0edd \
--key-name coreos \
--flavor m1.medium \
--num-instances 3 \
--security-groups default coreos
```

To use config drive you may need to add `--config-drive=true` to command above.

If you have more than one network, you may have to be explicit in the nova boot command.

```
--nic net-id=5b9c5ef6-28b9-4781-ac18-d7d86765fd38
```

You can see the IDs for your configured networks by running

```
nova network-list
+--------------------------------------+---------+------+
| ID                                   | Label   | Cidr |
+--------------------------------------+---------+------+
| f54b48c7-34fc-4828-8ee9-21b623c7b8f9 | public  | -    |
| 5b9c5ef6-28b9-4781-ac18-d7d86765fd38 | private | -    |
+--------------------------------------+---------+------+
```

Your first CoreOS cluster should now be running. The only thing left to do is
find an IP and SSH in.

```sh
$ nova list
+--------------------------------------+-----------------+--------+------------+-------------+-------------------+
| ID                                   | Name            | Status | Task State | Power State | Networks          |
+--------------------------------------+-----------------+--------+------------+-------------+-------------------+
| a1df1d98-622f-4f3b-adef-cb32f3e2a94d | coreos-a1df1d98 | ACTIVE | None       | Running     | private=10.0.0.3  |
| db13c6a7-a474-40ff-906e-2447cbf89440 | coreos-db13c6a7 | ACTIVE | None       | Running     | private=10.0.0.4  |
| f70b739d-9ad8-4b0b-bb74-4d715205ff0b | coreos-f70b739d | ACTIVE | None       | Running     | private=10.0.0.5  |
+--------------------------------------+-----------------+--------+------------+-------------+-------------------+
```

Finally SSH into an instance, note that the user is `core`:

```sh
$ chmod 400 core.pem
$ ssh -i core.pem core@10.0.0.3
   ______                ____  _____
  / ____/___  ________  / __ \/ ___/
 / /   / __ \/ ___/ _ \/ / / /\__ \
/ /___/ /_/ / /  /  __/ /_/ /___/ /
\____/\____/_/   \___/\____//____/

core@10-0-0-3 ~ $
```

## Adding More Machines

Adding new instances to the cluster is as easy as launching more with the same 
cloud-config. New instances will join the cluster assuming they can communicate 
with the others.

Example:

```sh
nova boot \
--user-data ./cloud-config.yaml \
--image cdf3874c-c27f-4816-bc8c-046b240e0edd \
--key-name coreos \
--flavor m1.medium \
--security-groups default coreos
```

## Multiple Clusters

If you would like to create multiple clusters you'll need to generate and use a
new discovery token. Change the token value on the etcd discovery parameter in the cloud-config, and boot new instances.

## Using CoreOS

Now that you have instances booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
