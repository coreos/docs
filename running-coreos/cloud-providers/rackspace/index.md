---
layout: docs
title: Rackspace Cloud
category: running_coreos
sub_category: cloud_provider
weight: 5
---

<div class="coreos-docs-banner">
<span class="glyphicon glyphicon-info-sign"></span>This image is now way easier to use! Read about our <a href="{{site.url}}/blog/new-filesystem-btrfs-cloud-config/">new file system layout and cloud-config support</a>.
</div>

# Running CoreOS {{site.rackspace-version}} on Rackspace

CoreOS is currently in heavy development and actively being tested.  These instructions will walk you through running CoreOS on the Rackspace Openstack cloud, which differs slightly from the generic Openstack instructions.


## Choosing a Channel

CoreOS is designed to be [updated automatically]({{site.url}}/using-coreos/updates) with different schedules per channel. You can [disable this feature]({{site.url}}/docs/cluster-management/debugging/prevent-reboot-after-update), although we don't recommend it. Release notes can currently be found on [Github](https://github.com/coreos/manifest/releases) but we're researching better options.

<div id="ec2-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.url}}/using-coreos/docker">docker</a>, <a href="{{site.url}}/using-coreos/etcd">etcd</a> and <a href="{{site.url}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.rackspace-version}}.</p>
      </div>
      <table>
        <thead>
          <tr>
            <th>Region</th>
            <th>Image ID</th>
            <th>Heat Template</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>All Regions</td>
            <td>{{site.rackspace-image-id}}</td>
            <td><a href="{{site.url}}/dist/rackspace/heat-alpha.yaml">heat-alpha.yaml</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config-docs]. You can provide cloud-config data via both Heat and Nova APIs. You **can not** provide cloud-config via the Control Panel. If you launch machines via the UI, you will have to do all configuration manually.

The most common Rackspace cloud-config looks like:

```
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

[cloud-config-docs]: {{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config

## Launch with Nova

We're going to install `rackspace-novaclient`, upload a keypair and boot the image id `{{site.rackspace-image-id}}`.

### Install Supernova Tool

If you don't have `pip` installed, install it by running `sudo easy_install pip`. Now let's use `pip` to install Supernova, a tool that lets you easily switch Rackspace regions. Be sure to install these in the order listed:

```
sudo pip install keyring
sudo pip install rackspace-novaclient
sudo pip install supernova
```

### Store Account Information 

Edit your config file (`~/.supernova`) to store your username, API key and some other settings. The `OS_TENANT_NAME` should also be set to your username.

```
[production]
OS_AUTH_URL = https://identity.api.rackspacecloud.com/v2.0/
OS_USERNAME = username
OS_PASSWORD = fd62afe2-4686-469f-9849-ceaa792c55a6
OS_TENANT_NAME = username
OS_REGION_NAME = DFW
```

We're ready to create a keypair then boot a server with it.

### Create Keypair

For this guide, I'm assuming you already have a public key you use for your CoreOS servers. Note that only RSA keypairs are supported. Load the public key to Rackspace:

```
supernova production keypair-add --pub-key ~/.ssh/coreos.pub coreos-key
```

Check you make sure the key is in your list by running `supernova production keypair-list`

```
+------------+-------------------------------------------------+
| Name       | Fingerprint                                     |
+------------+-------------------------------------------------+
| coreos-key | d0:6b:d8:3a:3e:6a:52:43:32:bc:01:ea:c2:0f:49:59 |
+------------+-------------------------------------------------+
```

### Boot a Server

Boot a new server with our new keypair and specify optional cloud-config data.

```
supernova production boot --image {{site.rackspace-image-id}} --flavor performance1-2 --key-name coreos-key --user-data ~/cloud_config.yml --config-drive true My_CoreOS_Server
```

You should now see the details of your new server in your terminal and it should also show up in the control panel:

```
+------------------------+--------------------------------------+
| Property               | Value                                |
+------------------------+--------------------------------------+
| status                 | BUILD                                |
| updated                | 2013-11-02T19:43:45Z                 |
| hostId                 |                                      |
| key_name               | coreos-key                           |
| image                  | CoreOS                               |
| OS-EXT-STS:task_state  | scheduling                           |
| OS-EXT-STS:vm_state    | building                             |
| flavor                 | 512MB Standard Instance              |
| id                     | 82dbe66d-0762-4cba-a286-8c1af8431e47 |
| user_id                | 3c55bca772ba4a4bb6a4eb5b25754738     |
| name                   | My_CoreOS_Server                     |
| adminPass              | mgNqEx7I9pQA                         |
| tenant_id              | 833111                               |
| created                | 2013-11-02T19:43:44Z                 |
| OS-DCF:diskConfig      | MANUAL                               |
| accessIPv4             |                                      |
| accessIPv6             |                                      |
| progress               | 0                                    |
| OS-EXT-STS:power_state | 0                                    |
| metadata               | {}                                   |
+------------------------+--------------------------------------+
```

### Launching More Servers

To launch more servers and have them join your cluster, simply provide the same cloud-config.

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
