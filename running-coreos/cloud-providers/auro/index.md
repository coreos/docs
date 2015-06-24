---
layout: docs
title: AURO Cloud
category: running_coreos
sub_category: cloud_provider
weight: 5
---

# Running CoreOS on AURO

AURO is a Canadian OpenStack cloud computing provider based in Canada. In
order to get started, you must have an active account on the AURO
[public cloud computing][cloud-compute] service.

The following instructions will walk you through setting up the `nova` tool with
your appropriate credentials and launching your first cluster using the
CLI tools.

[cloud-compute]: https://www.auro.io/public_cloud_hosting/product

## Choosing a Channel

CoreOS is released into stable, alpha, and beta channels. Releases to each channel serve
as a release-candidate for the next channel. For example, a bug-free alpha
release is promoted bit-for-bit to the beta channel.

CoreOS releases are automatically built and deployed on the AURO cloud,
therefore it is best to launch your clusters with the following naming pattern:
CoreOS _Channel_ _Version_.  For example, the image name of the latest alpha
release will be "CoreOS Alpha {{site.alpha-channel}}".


### Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on
startup and more via [cloud-config][cloud-config].  We're going to provide the
`cloud-config` data via the `user-data` flag.

[cloud-config]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config

You are able to supply the `user-data` using the AURO control panel when launching
an instance, in the "Post Creation" tab, as well as using the CLI to deploy your
cluster on the AURO cloud.

A sample common `cloud-config` file will look something like the following:

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

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on AURO.

## Launch Cluster

You will need to install `python-novaclient` which supplies the OpenStack CLI
tools as well as a keypair to use in order to access your CoreOS cluster.

### Install OpenStack CLI tools

If you don't have `pip` installed, install it by running `sudo easy_install pip`.
Now let's use `pip` to install `python-novaclient`.

```sh
$ sudo pip install python-novaclient
```

### Add API Credentials

You will need to have your API credentials configured on the machine that you're
going to be launching your cluster from.  The easiest way to do this is by
logging into the AURO control panel and in the "Access & Security" section go to
the "API Access" tab and clicking "Download OpenStack RC File".

From there, you must create a file on your system with the contents of the
`<project name>-openrc.sh` file provided.  Once done, you will need to `source` that file in your
shell prior to running any API commands.  You can test that everything is running
properly by running the following command:

```sh
$ source <project name>-openrc.sh
$ nova credentials
```

### Create Keypair

You can import an existing public key by using the `nova keypair-add` command,
however for this guide, we will be creating a new keypair and storing the
private key for it locally and use it to access our CoreOS cluster.

```sh
$ nova keypair-add coreos-key > coreos.pem
```

### Create Servers

You should now be ready to launch the servers which will create your CoreOS
cluster using the `nova` CLI command.

<div id="AURO-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.baseurl}}/using-coreos/docker">docker</a>, <a href="{{site.baseurl}}/using-coreos/etcd">etcd</a> and <a href="{{site.baseurl}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
      <pre>nova boot --user-data ./cloud-config.yaml --image "CoreOS Alpha {{site.alpha-channel}}" --key-name coreos-key --flavor standard-1 --num-instances 3 --security-groups default coreos</pre>
    </div>
    <div class="tab-pane active" id="beta-create">
      <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
      <pre>nova boot --user-data ./cloud-config.yaml --image "CoreOS Beta {{site.beta-channel}}" --key-name coreos-key --flavor standard-1 --num-instances 3 --security-groups default coreos</pre>
    </div>
  </div>
</div>

Once that's done, your cluster should be up and running.  You can list the
created servers and SSH into a server using your private key.

```sh
$ nova list
+--------------------------------------+-----------------+--------+------------+-------------+---------------------------------------+
| ID                                   | Name            | Status | Task State | Power State | Networks                              |
+--------------------------------------+-----------------+--------+------------+-------------+---------------------------------------+
| a1df1d98-622f-4f3b-adef-cb32f3e2a94d | coreos-a1df1d98 | ACTIVE | None       | Running     | public=104.36.x.x; private=172.22.x.x |
| db13c6a7-a474-40ff-906e-2447cbf89440 | coreos-db13c6a7 | ACTIVE | None       | Running     | public=104.36.x.x; private=172.22.x.x |
| f70b739d-9ad8-4b0b-bb74-4d715205ff0b | coreos-f70b739d | ACTIVE | None       | Running     | public=104.36.x.x; private=172.22.x.x |
+--------------------------------------+-----------------+--------+------------+-------------+---------------------------------------+
$ nova ssh --login core -i core.pem coreos-a1df1d98
CoreOS (alpha)
core@a1df1d98-622f-4f3b-adef-cb32f3e2a94d ~ $
```

## Adding More Machines

Adding new instances to the cluster is as easy as launching more with the same
cloud-config. New instances will join the cluster assuming they can communicate
with the others.

## Multiple Clusters

If you would like to create multiple clusters you'll need to generate and use a
new discovery token. Change the token value on the etcd discovery parameter in the cloud-config, and boot new instances.

## Using CoreOS

Now that you have instances booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
