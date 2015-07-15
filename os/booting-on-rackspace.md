# Running CoreOS on Rackspace

CoreOS is currently in heavy development and actively being tested.  These instructions will walk you through running CoreOS on the Rackspace OpenStack cloud, which differs slightly from the generic OpenStack instructions. There are two ways to launch a CoreOS cluster: launch an entire cluster with Heat or launch machines with Nova.


## Choosing a Channel

CoreOS is designed to be [updated automatically]({{site.baseurl}}/using-coreos/updates) with different schedules per channel. You can [disable this feature]({{site.baseurl}}/docs/cluster-management/debugging/prevent-reboot-after-update), although we don't recommend it. Read the [release notes]({{site.baseurl}}/releases) for specific features and bug fixes.

<div id="rax-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.baseurl}}/using-coreos/docker">docker</a>, <a href="{{site.baseurl}}/using-coreos/etcd">etcd</a> and <a href="{{site.baseurl}}/using-coreos/clustering">fleet</a> will be available for testing.
        {% if site.data.alpha-channel.rackspace-version != site.data.alpha-channel.rackspace-onmetal-version %}
          Current version for Cloud Servers is CoreOS {{site.data.alpha-channel.rackspace-version}} and the current version for OnMetal servers is {{site.data.alpha-channel.rackspace-onmetal-version}}.
        {% elsif site.data.alpha-channel.rackspace-version == site.data.alpha-channel.rackspace-onmetal-version %}
          Current version is CoreOS {{site.data.alpha-channel.rackspace-version}}.
        {% endif %}
        </p>
      </div>
      <table>
        <thead>
          <tr>
            <th>Server Type</th>
            <th>Image ID</th>
            <th>Heat Template</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Cloud Servers</td>
            <td>{{site.data.alpha-channel.rackspace-image-id}}</td>
            <td><a href="{{site.baseurl}}/dist/rackspace/heat-alpha.yaml">heat-alpha.yaml</td>
          </tr>
          <tr>
            <td>OnMetal</td>
            <td>{{site.data.alpha-channel.rackspace-onmetal-id}}</td>
            <td><a href="{{site.baseurl}}/dist/rackspace/heat-onmetal-alpha.yaml">heat-onmetal-alpha.yaml</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The beta channel consists of promoted alpha releases.
        {% if site.data.beta-channel.rackspace-version != site.data.beta-channel.rackspace-onmetal-version %}
          Current version for Cloud Servers is CoreOS {{site.data.beta-channel.rackspace-version}} and the current version for OnMetal servers is {{site.data.beta-channel.rackspace-onmetal-version}}.
        {% elsif site.data.beta-channel.rackspace-version == site.data.beta-channel.rackspace-onmetal-version %}
          Current version is CoreOS {{site.data.beta-channel.rackspace-version}}.
        {% endif %}
        </p>
      </div>
      <table>
        <thead>
          <tr>
            <th>Server Type</th>
            <th>Image ID</th>
            <th>Heat Template</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Cloud Server</td>
            <td>{{site.data.beta-channel.rackspace-image-id}}</td>
            <td><a href="{{site.baseurl}}/dist/rackspace/heat-beta.yaml">heat-beta.yaml</td>
          </tr>
          <tr>
            <td>OnMetal</td>
            <td>{{site.data.beta-channel.rackspace-onmetal-id}}</td>
            <td><a href="{{site.baseurl}}/dist/rackspace/heat-onmetal-beta.yaml">heat-onmetal-beta.yaml</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted.
        {% if site.data.stable-channel.rackspace-version != site.data.stable-channel.rackspace-onmetal-version %}
          Current version for Cloud Servers is CoreOS {{site.data.stable-channel.rackspace-version}} and the current version for OnMetal servers is {{site.data.stable-channel.rackspace-onmetal-version}}.
        {% elsif site.data.stable-channel.rackspace-version == site.data.stable-channel.rackspace-onmetal-version %}
          Current version is CoreOS {{site.data.stable-channel.rackspace-version}}.
        {% endif %}
        </p>
      </div>
      <table>
        <thead>
          <tr>
            <th>Server Type</th>
            <th>Image ID</th>
            <th>Heat Template</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Cloud Server</td>
            <td>{{site.data.stable-channel.rackspace-image-id}}</td>
            <td><a href="{{site.baseurl}}/dist/rackspace/heat-stable.yaml">heat-stable.yaml</td>
          </tr>
          <tr>
            <td>OnMetal</td>
            <td>{{site.data.stable-channel.rackspace-onmetal-id}}</td>
            <td><a href="{{site.baseurl}}/dist/rackspace/heat-onmetal-stable.yaml">heat-onmetal-stable.yaml</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config-docs]. Cloud-config is intended to bring up a cluster of machines into a minimal useful state and ideally shouldn't be used to configure anything that isn't standard across many hosts. Once a machine is created on Rackspace, the cloud-config can't be modified.

You can provide cloud-config data via both Heat and Nova APIs. You **cannot** provide cloud-config via the Control Panel. If you launch machines via the UI, you will have to do all configuration manually.

The most common Rackspace cloud-config looks like:

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
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
```

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on Rackspace.

[cloud-config-docs]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config

### Mount Data Disk

Certain server flavors have separate system and data disks. To utilize the data disks, they must be mounted with a `.mount` unit. Check to make sure the `Where=` parameter accurately reflects the location of the block device:

```yaml
#cloud-config
coreos:
  units:
    - name: media-data.mount
      command: start
      content: |
        [Mount]
        What=/dev/xvde
        Where=/media/data
        Type=ext3
```

Mounting Cloud Block Storage can be done with a mount unit, but should not be included in cloud-config unless the disk is present on the first boot.

For more general information, check out [mounting storage on CoreOS]({{site.baseurl}}/docs/cluster-management/setup/mounting-storage).

## Launch with Nova

We're going to install `rackspace-novaclient`, upload a keypair and boot the image id from above.

### Install Supernova Tool

The Supernova tool requires Python and `pip`, a Python package manger. If you don't have `pip` installed, install it by running `sudo easy_install pip`. Now let's use `pip` to install Supernova, a tool that lets you easily switch Rackspace regions. Be sure to install these in the order listed:

```sh
sudo pip install keyring
sudo pip install rackspace-novaclient
sudo pip install supernova
```

### Store Account Information 

Edit your config file (`~/.supernova`) to store your Rackspace username, API key (referenced as `OS_PASSWORD`) and some other settings. The `OS_TENANT_NAME` should be set to your Rackspace account ID, which can be found by clicking on your Rackspace username in the upper right-hand corner of the cloud control panel UI.

```ini
[production]
OS_AUTH_URL = https://identity.api.rackspacecloud.com/v2.0/
OS_USERNAME = username
OS_PASSWORD = fd62afe2-4686-469f-9849-ceaa792c55a6
OS_TENANT_NAME = 123456
OS_REGION_NAME = DFW
OS_AUTH_SYSTEM = rackspace
```

We're ready to create a keypair then boot a server with it.

### Create Keypair

For this guide, I'm assuming you already have a public key you use for your CoreOS servers. Note that only RSA keypairs are supported. Load the public key to Rackspace:

```sh
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

<div id="rax-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>Boot a new Cloud Server with our new keypair and specify optional cloud-config data:</p>
      <pre>supernova production boot --image {{site.data.alpha-channel.rackspace-image-id}} --flavor performance1-2 --key-name coreos-key --user-data ~/cloud_config.yml --config-drive true My_CoreOS_Server</pre>
      <p>Boot a new OnMetal Server with our new keypair and specify optional cloud-config data:</p>
      <pre>supernova production boot --image {{site.data.alpha-channel.rackspace-onmetal-id}} --flavor onmetal-compute1 --key-name coreos-key --user-data ~/cloud_config.yml --config-drive true My_CoreOS_Server</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>Boot a new Cloud Server with our new keypair and specify optional cloud-config data:</p>
      <pre>supernova production boot --image {{site.data.beta-channel.rackspace-image-id}} --flavor performance1-2 --key-name coreos-key --user-data ~/cloud_config.yml --config-drive true My_CoreOS_Server</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>Boot a new Cloud Server with our new keypair and specify optional cloud-config data:</p>
      <pre>supernova production boot --image {{site.data.stable-channel.rackspace-image-id}} --flavor performance1-2 --key-name coreos-key --user-data ~/cloud_config.yml --config-drive true My_CoreOS_Server</pre>
    </div>
  </div>
</div>

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

## Launch with Heat

We're going to install the `heat` tool, then use it to create a new stack with the specified number of machines, server flavor, SSH key and user-data.

### Install Heat CLI

First, install the [Heat CLI](https://github.com/openstack/python-heatclient) with `sudo pip install python-heatclient`. You can view the [full instructions](http://docs.rackspace.com/orchestration/api/v1/orchestration-getting-started/content/Install_Heat_Client.html) if needed.

Second, verify that you're exporting your credentials for the CLI to use in your `~/bash_profile`:

```sh
export OS_AUTH_URL=https://identity.api.rackspacecloud.com/v2.0/
export OS_USERNAME=<username>
export OS_TENANT_ID=<tenant_id>
export HEAT_URL=https://ord.orchestration.api.rackspacecloud.com/v1/${OS_TENANT_ID}  
export OS_PASSWORD=<password>
export OS_AUTH_SYSTEM=rackspace
```

If you have credentials already set up for use with the Nova CLI, they may conflict due to oddities in these tools. Re-source your credentials:

```sh
source ~/.bash_profile
```

### Launch the Stack

<div id="rax-heat">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-heat" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-heat" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-heat" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-heat">
      <p>Launch the stack by providing the specified parameters. This command will reference the local file <code>data.yml</code> in the current working directory that contains the cloud-config parameters. <code>$(< data.yaml)</code> prints the contents of this file into our heat command:</p>
      <pre>heat stack-create Test --template-file https://coreos.com/dist/rackspace/heat-alpha.yaml -P key-name=coreos-key -P flavor='2 GB Performance' -P count=5 -P user-data="$(< data.yaml)" -P name="CoreOS-alpha"</pre>
      <p>You can view the <a href="{{site.baseurl}}/dist/rackspace/heat-alpha.yaml">template here</a>.</p>
      <p>To boot an OnMetal cluster, use a slightly modified template:</p>
      <pre>heat stack-create Test --template-file https://coreos.com/dist/rackspace/heat-onmetal-alpha.yaml -P key-name=coreos-key -P flavor='2 GB Performance' -P count=3 -P user-data="$(< data.yaml)" -P name="CoreOS-alpha"</pre>
      <p>You can view the <a href="{{site.baseurl}}/dist/rackspace/heat-onmetal-alpha.yaml">template here</a>.</p>
    </div>
    <div class="tab-pane" id="beta-heat">
      <p>Launch the stack by providing the specified parameters. This command will reference the local file <code>data.yml</code> in the current working directory that contains the cloud-config parameters. <code>$(< data.yaml)</code> prints the contents of this file into our heat command:</p>
      <pre>heat stack-create Test --template-file https://coreos.com/dist/rackspace/heat-beta.yaml -P key-name=coreos-key -P flavor='2 GB Performance' -P count=5 -P user-data="$(< data.yaml)" -P name="CoreOS-beta"</pre>
      <p>You can view the <a href="{{site.baseurl}}/dist/rackspace/heat-beta.yaml">template here</a>.</p>
    </div>
    <div class="tab-pane active" id="stable-heat">
      <p>Launch the stack by providing the specified parameters. This command will reference the local file <code>data.yml</code> in the current working directory that contains the cloud-config parameters. <code>$(< data.yaml)</code> prints the contents of this file into our heat command:</p>
      <pre>heat stack-create Test --template-file https://coreos.com/dist/rackspace/heat-stable.yaml -P key-name=coreos-key -P flavor='2 GB Performance' -P count=5 -P user-data="$(< data.yaml)" -P name="CoreOS-stable"</pre>
      <p>You can view the <a href="{{site.baseurl}}/dist/rackspace/heat-stable.yaml">template here</a>.</p>
    </div>
  </div>
</div>

## Launch via Control Panel

You can also launch servers with either the `alpha` and `beta` channel versions via the web-based Control Panel, although you can't provide cloud-config via the UI. To do so: 
 
 1. Log into your Rackspace Control Panel
 2. Click on 'Servers'
 3. Click on 'Create Server'
 4. Choose server name and region
 5. Click on 'Linux', then on 'CoreOS' and finally choose '(alpha)' or '(beta)' version
 ![Control Panel Selection](http://57711b76b91f5d65a382-e5576ae0d6cf44f41aa69b4e6e0902ca.r62.cf1.rackcdn.com/Screen%20Shot%202014-06-30%20at%209.54.43%20AM.png)  
 6. Choose flavor and use 'Advanced Options' to select SSH Key -- if available
 7. Click on 'Create Server'


## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
