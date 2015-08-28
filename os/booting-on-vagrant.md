# Running CoreOS on Vagrant

Running CoreOS with Vagrant is the easiest way to bring up a single machine or virtualize an entire cluster on your laptop. Since the true power of CoreOS can be seen with a cluster, we're going to concentrate on that. Instructions for a single machine can be found [towards the end](#single-machine) of the guide.

You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Install Vagrant and VirtualBox

Vagrant is a simple-to-use command line virtual machine manager. There are install packages available for Windows, Linux and OS X. Find the latest installer on the [Vagrant downloads page][vagrant]. Be sure to get version 1.6.3 or greater.

[vagrant]: http://www.vagrantup.com/downloads.html

Vagrant can use either the free VirtualBox provider or the commercial VMware provider. Instructions for both are below. For the VirtualBox provider, version 4.3.10 or greater is required.

## Clone Vagrant Repo

Now that you have Vagrant installed you can bring up a CoreOS instance.

The following commands will clone a repository that contains the CoreOS Vagrantfile. This file tells Vagrant where it can find the latest disk image of CoreOS. Vagrant will download the image the first time you attempt to start the VM.

```sh
git clone https://github.com/coreos/coreos-vagrant.git
cd coreos-vagrant
```

## Starting a Cluster

To start our cluster, we need to provide some config parameters in cloud-config format via the `user-data` file and set the number of machines in the cluster in `config.rb`.

### Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on start-up and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config-docs]. You can provide cloud-config data to your CoreOS Vagrant VM by editing the `user-data` file inside of the cloned directory. A sample file `user-data.sample` exists as a base and must be renamed to `user-data` for it to be processed.

Our cluster will use an etcd [discovery URL]({{site.baseurl}}/docs/cluster-management/setup/etcd-cluster-discovery/) to bootstrap the cluster of machines and elect an initial etcd leader. Be sure to replace `<token>` with your own URL from [https://discovery.etcd.io/new](https://discovery.etcd.io/new):

```yaml
#cloud-config

coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    # WARNING: replace each time you 'vagrant destroy'
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380
  fleet:
    public-ip: $public_ipv4
  flannel:
    interface: $public_ipv4
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
    - name: flanneld.service
      drop-ins:
      - name: 50-network-config.conf
        content: |
          [Service]
          ExecStartPre=/usr/bin/etcdctl set /coreos.com/network/config '{ "Network": "10.1.0.0/16" }'
      # Uncomment line above if you want to use flannel in your installation.
      # command: start
```

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on Vagrant. They will map to the first statically defined private and public networks defined in the Vagrantfile.

There is no need to add an SSH key since Vagrant will automatically generate and use it's own SSH key. Any keys added will be overwritten.

Your Vagrantfile should copy your cloud-config file to `/var/lib/coreos-vagrant/vagrantfile-user-data`. The provided Vagrantfile is already configured to do this. `cloudinit` reads `vagrantfile-user-data` on every boot and uses it to create the machine's user-data file.

If you need to update your cloud-config later on, run `vagrant reload --provision` to reboot your VM and apply the new file.

[cloud-config-docs]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config

### Start up CoreOS

The `config.rb.sample` file contains a few useful settings about your Vagrant environment and most importantly, how many machines you'd like in your cluster.

CoreOS is designed to be [updated automatically]({{site.baseurl}}/using-coreos/updates) with different schedules per channel. Select the channel you'd like to use for this cluster below. Read the [release notes]({{site.baseurl}}/releases) for specific features and bug fixes.

<div id="vagrant-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.baseurl}}/using-coreos/docker">docker</a>, <a href="{{site.baseurl}}/using-coreos/etcd">etcd</a> and <a href="{{site.baseurl}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
      <p>Rename the file to <code>config.rb</code> and modify a few lines:</p>
      <h4>config.rb</h4>
      <pre># Size of the CoreOS cluster created by Vagrant
$num_instances=3</pre>
      <pre># Official CoreOS channel from which updates should be downloaded
$update_channel='alpha'</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
      <p>Rename the file to <code>config.rb</code> then uncomment and modify:</p>
      <h4>config.rb</h4>
      <pre># Size of the CoreOS cluster created by Vagrant
$num_instances=3</pre>
      <pre># Official CoreOS channel from which updates should be downloaded
$update_channel='beta'</pre>
    </div>
	<div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted. Current version is CoreOS {{site.stable-channel}}.</p>
      <p>Rename the file to <code>config.rb</code> then uncomment and modify:</p>
      <h4>config.rb</h4>
      <pre># Size of the CoreOS cluster created by Vagrant
$num_instances=3</pre>
      <pre># Official CoreOS channel from which updates should be downloaded
$update_channel='stable'</pre>
    </div>
  </div>
</div>

#### Start Machines Using Vagrant's default VirtualBox Provider

Start the machine(s):

```sh
vagrant up
```

List the status of the running machines:

```sh
$ vagrant status
Current machine states:

core-01                   running (virtualbox)
core-02                   running (virtualbox)
core-03                   running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

Connect to one of the machines:

```sh
vagrant ssh core-01 -- -A
```

#### Start Machines Using Vagrant's VMware Provider

If you have purchased the [VMware Vagrant provider](http://www.vagrantup.com/vmware), run the following commands:

```sh
vagrant up --provider vmware_fusion
vagrant ssh core-01 -- -A
```

## Single Machine

To start a single machine, we need to provide some config parameters in cloud-config format via the `user-data` file.

### Cloud-Config

This cloud-config starts etcd and fleet when the machine is booted:

```yaml
#cloud-config

coreos:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    # WARNING: replace each time you 'vagrant destroy'
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380
  fleet:
      public-ip: $public_ipv4
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
```

### Start up CoreOS

The `config.rb.sample` file contains a few useful settings about your Vagrant environment. We're going to set the CoreOS channel that we'd like the machine to track.</p>

<div id="vagrant-single">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-single" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-single" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-single" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-single">
      <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.baseurl}}/using-coreos/docker">docker</a>, <a href="{{site.baseurl}}/using-coreos/etcd">etcd</a> and <a href="{{site.baseurl}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
      <p>Rename the file to <code>config.rb</code> then uncomment and modify:</p>
      <h4>config.rb</h4>
      <pre># Official CoreOS channel from which updates should be downloaded
$update_channel='alpha'</pre>
    </div>
    <div class="tab-pane" id="beta-single">
      <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
      <p>Rename the file to <code>config.rb</code> then uncomment and modify:</p>
      <h4>config.rb</h4>
      <pre># Official CoreOS channel from which updates should be downloaded
$update_channel='beta'</pre>
    </div>
    <div class="tab-pane active" id="stable-single">
      <p>The Stable channel should be used by production clusters. Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted. Current version is CoreOS {{site.stable-channel}}.</p>
      <p>Rename the file to <code>config.rb</code> then uncomment and modify:</p>
      <h4>config.rb</h4>
      <pre># Official CoreOS channel from which updates should be downloaded
$update_channel='stable'</pre>
    </div>
  </div>
</div>

#### Start Machine Using Vagrant's default VirtualBox Provider

Start the machine:

```sh
vagrant up
```

Connect to the machine:

```sh
vagrant ssh core-01 -- -A
```

#### Start Machine Using Vagrant's VMware Provider

If you have purchased the [VMware Vagrant provider](http://www.vagrantup.com/vmware), run the following commands:

```sh
vagrant up --provider vmware_fusion
vagrant ssh core-01 -- -A
```

## Shared Folder Setup

Optionally, you can share a folder from your laptop into the virtual machine. This is useful for easily getting code and Dockerfiles into CoreOS.

```ini
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

After a 'vagrant reload' you will be prompted for your local machine password.

## New Box Versions

CoreOS is a rolling release distribution and versions that are out of date will automatically update.
If you want to start from the most up to date version you will need to make sure that you have the latest box file of CoreOS.
You can do this using `vagrant box update` - or, simply remove the old box file and Vagrant will download the latest one the next time you `vagrant up`.

```sh
vagrant box remove coreos-alpha vmware_fusion
vagrant box remove coreos-alpha virtualbox
```

If you'd like to download the box separately, you can download the URL contained in the Vagrantfile and add it manually:

```sh
vagrant box add coreos-alpha <path-to-box-file>
```

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide, learn about [CoreOS clustering with Vagrant]({{site.baseurl}}/blog/coreos-clustering-with-vagrant/), or dig into [more specific topics]({{site.baseurl}}/docs).
