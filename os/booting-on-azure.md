# Running CoreOS on Azure

## Choosing a Channel

CoreOS is designed to be [updated automatically][update-docs] with different
schedules per channel. You can [disable this feature][reboot-docs], although we
don't recommend it. Read the [release notes][release-notes] for specific
features and bug fixes.

The following command will create a single instance. For more details, check out
<a href="#via-the-cross-platform-cli">Launching via the cross-platform CLI</a>.

<div id="azure-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and frequently has new releases. The newest versions of <a href="{{site.baseurl}}/using-coreos/docker">Docker</a>, <a href="{{site.baseurl}}/using-coreos/etcd">etcd</a>, and <a href="{{site.baseurl}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
        <pre>azure vm create --custom-data=cloud-config.yaml --vm-size=Small --ssh=22 --ssh-cert=path/to/cert --no-ssh-password --vm-name=node-1 --location="West US" my-cloud-service 2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-{{site.alpha-channel}} core</pre>
      </div>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
        <pre>azure vm create --custom-data=cloud-config.yaml --vm-size=Small --ssh=22 --ssh-cert=path/to/cert --no-ssh-password --vm-name=node-1 --location="West US" my-cloud-service 2b171e93f07c4903bcad35bda10acf22__CoreOS-Beta-{{site.beta-channel}} core</pre>
      </div>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted. Current version is CoreOS {{site.stable-channel}}.</p>
        <pre>azure vm create --custom-data=cloud-config.yaml --vm-size=Small --ssh=22 --ssh-cert=path/to/cert --no-ssh-password --vm-name=node-1 --location="West US" my-cloud-service 2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-{{site.stable-channel}} core</pre>
      </div>
    </div>
  </div>
</div>

[update-docs]: {{site.baseurl}}/using-coreos/updates
[reboot-docs]: {{site.baseurl}}/docs/cluster-management/debugging/prevent-reboot-after-update
[release-notes]: {{site.baseurl}}/releases

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on
startup, and more via cloud-config. Jump over to the [docs to learn about the
supported features][cloud-config-docs]. Cloud-config is intended to bring up a
cluster of machines into a minimal useful state and ideally shouldn't be used
to configure anything that isn't standard across many hosts. Once an instance
is provisioned on Azure, the cloud-config cannot be modified.

You can provide raw cloud-config data to CoreOS
<a href="#via-the-cross-platform-cli">via the Azure cross-platform CLI</a>.

The most common cloud-config for Azure looks like:

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

The `$private_ipv4` and `$public_ipv4` substitution variables are fully
supported in cloud-config on Azure. The private address is the address of the
single network interface of the instance and the public address is the address
of the cloud service to which the instance belongs.

[cloud-config-docs]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config

### Adding More Machines
To add more instances to the cluster, just launch more with the same
cloud-config into the same cloud service. Make sure to use the `--connect`
flag with `azure vm create` to add a new instance to your existing cloud
service.

## Launching Instances

### Via the Cross-Platform CLI

Follow the [installation and configuration guides][xplat-cli] for the Azure
Cross-Platform CLI to set up your local installation. This tool can be used to
perform most of the needed tasks.

Instances on Azure must be connected to a cloud service. Create a new cloud
service with the following command:

```sh
azure service create my-cloud-service
```

All of the instances within a cloud service can connect to one another via
their private network interface. Instances within a cloud service are
effectively NAT'd behind the cloud service's address; the public address. To
allow connections from outside the cloud service, you'll need to create an
endpoint with `azure vm endpoint create`. For now, we'll keep it simple and
only connect to other machines within our cloud-service.

In order to SSH into your machine, you'll need an x509 certificate. You
probably already have an SSH key, which you can use to generate an x509
certificate. More detail can be found in [this guide][ssh].

Now that you have a cloud service and your keys, create an instance of CoreOS
Alpha {{site.alpha-channel}}, connected to your cloud service:

```sh
azure vm create --custom-data=cloud-config.yaml --ssh=22 --ssh-cert=path/to/cert --no-ssh-password --vm-name=node-1 --connect=my-cloud-service 2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-{{site.alpha-channel}} core
```

This will additionally create an endpoint allowing SSH traffic to reach the
newly created instance. If you bring up more machines, you'll need to choose a
different port for each instance.

Let's create two more instances:

```sh
azure vm create --custom-data=cloud-config.yaml --ssh=2022 --ssh-cert=path/to/cert --no-ssh-password --vm-name=node-2 --connect=my-cloud-service 2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-{{site.alpha-channel}} core
```

```sh
azure vm create --custom-data=cloud-config.yaml --ssh=3022 --ssh-cert=path/to/cert --no-ssh-password --vm-name=node-3 --connect=my-cloud-service 2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-{{site.alpha-channel}} core
```

If you used the recommended <a href="#cloud-config">cloud-config</a>, you
should have a working, three node cluster. Great job!

[xplat-cli]: http://azure.microsoft.com/en-us/documentation/articles/xplat-cli/
[ssh]: http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-use-ssh-key/

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart][quick-start] guide or dig into
[more specific topics][docs].

[quick-start]: {{site.baseurl}}/docs/quickstart
[docs]: {{site.baseurl}}/docs
