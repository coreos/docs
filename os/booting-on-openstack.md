# Running CoreOS Container Linux on OpenStack

These instructions will walk you through downloading Container Linux for OpenStack, importing it with the `glance` tool, and running your first cluster with the `nova` tool.

## Import the image

These steps will download the Container Linux image, uncompress it, and then import it into the glance image store.

## Choosing a channel

Container Linux is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

<div id="openstack-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
<pre>
$ wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
<pre>
$ wget https://beta.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
</pre>
    </div>
  <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
<pre>
$ wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
$ bunzip2 coreos_production_openstack_image.img.bz2
</pre>
    </div>
  </div>
</div>

Once the download completes, add the Container Linux image into Glance:

```sh
$ glance image-create --name Container-Linux \
  --container-format bare \
  --disk-format qcow2 \
  --file coreos_production_openstack_image.img
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
| is_public        | False                                |
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

Optionally add the `--visibility public` flag to make this image available outside of the configured OpenStack account tenant.

## Container Linux Configs

Container Linux allows you to configure machine parameters, launch systemd units on startup and more via Container Linux Configs. These configs are then transpiled into Ignition configs and given to booting machines. Jump over to the [docs to learn about the supported features][cl-configs]. We're going to provide our Container Linux Config to OpenStack via the user-data flag. Our Container Linux Config will also contain SSH keys that will be used to connect to the instance. In order for this to work your OpenStack cloud provider must support [config drive][config-drive] or the OpenStack metadata service.

[cl-configs]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/getting-started.md
[config-drive]: http://docs.openstack.org/user-guide/cli_config_drive.html

A common Container Linux Config for OpenStack looks like:

```container-linux-config:openstack-metadata
etcd:
  # All options get passed as command line flags to etcd.
  # Any information inside curly braces comes from the machine at boot time.

  # multi_region and multi_cloud deployments need to use {PUBLIC_IPV4}
  advertise_client_urls:       "http://{PRIVATE_IPV4}:2379"
  initial_advertise_peer_urls: "http://{PRIVATE_IPV4}:2380"
  # listen on both the official ports and the legacy ports
  # legacy ports can be omitted if your application doesn't depend on them
  listen_client_urls:          "http://0.0.0.0:2379"
  listen_peer_urls:            "http://{PRIVATE_IPV4}:2380"
  # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
  # specify the initial size of your cluster with ?size=X
  discovery:                   "https://discovery.etcd.io/<token>"
```

The `{PRIVATE_IPV4}` and `{PUBLIC_IPV4}` substitution variables are fully supported in Container Linux Configs on OpenStack deployments using the metadata service. Unfortunately systems relying on config drive are currently unsupported.

## Launch cluster

Boot the machines with the `nova` CLI, referencing the image ID from the import step above and your [JSON file from ct](cl-configs):

```sh
nova boot \
--user-data ./config.ign \
--image cdf3874c-c27f-4816-bc8c-046b240e0edd \
--key-name coreos \
--flavor m1.medium \
--min-count 3 \
--security-groups default,coreos
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

Your first Container Linux cluster should now be running. The only thing left to do is find an IP and SSH in.

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

## Adding more machines

Adding new instances to the cluster is as easy as launching more with the same Container Linux Config. New instances will join the cluster assuming they can communicate with the others.

Example:

```sh
nova boot \
--user-data ./config.ign \
--image cdf3874c-c27f-4816-bc8c-046b240e0edd \
--key-name coreos \
--flavor m1.medium \
--security-groups default,coreos
```

## Multiple clusters

If you would like to create multiple clusters you'll need to generate and use a new discovery token. Change the token value on the etcd discovery parameter in the Container Linux Config, and boot new instances.

## Using CoreOS Container Linux

Now that you have instances booted it is time to play around. Check out the [Container Linux Quickstart](quickstart.md) guide or dig into [more specific topics](https://coreos.com/docs).
