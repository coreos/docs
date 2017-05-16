# Running CoreOS Container Linux on Microsoft Azure

## Choosing a channel

Container Linux is designed to be [updated automatically][update-docs] with different schedules per channel. This feature can be [disabled][reboot-docs], although it is not recommended. The [release notes][release-notes] contain information about specific features and bug fixes.

The following command will create a single instance. For more details, check out [Launching via the Microsoft Azure CLI][azurecli-heading].

<div id="azure-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
        <pre>az vm create --name node-1 --resource-group group-1 --admin-username core --custom-data "$(cat config.ign)" --image CoreOS:CoreOS:Alpha:latest</pre>
      </div>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
        <pre>az vm create --name node-1 --resource-group group-1 --admin-username core --custom-data "$(cat config.ign)" --image CoreOS:CoreOS:Beta:latest</pre>
      </div>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
        <pre>az vm create --name node-1 --resource-group group-1 --admin-username core --custom-data "$(cat config.ign)" --image CoreOS:CoreOS:Stable:latest</pre>
      </div>
    </div>
  </div>
</div>

## Container Linux Config

Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via a Container Linux Config. Head over to the [docs to learn how to use Container Linux Configs][cl-configs]. Note that Microsoft Azure doesn't allow an instance's userdata to be modified after the instance has been launched. This isn't a problem since Ignition, the tool that consumes the userdata, only runs on the first boot.

You can provide a raw Ignition config (produced from a Container Linux Config) to Container Linux [via the Microsoft Azure CLI][azurecli-heading].

As an example, this config will configure and start etcd:

```yaml container-linux-config:azure
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

## Launching instances

### Via the Microsoft Azure CLI

Follow the [installation and configuration guides][azure-cli] for the Microsoft Azure CLI to set up your local installation.

Instances on Microsoft Azure must be created within a resource group. Create a new resource group with the following command:

```sh
az group create --name group-1 --location <location>
```

Now that you have a resource group, create an instance of Container Linux Alpha inside it:

```sh
az vm create --name node-1 --resource-group group-1 --admin-username core --custom-data "$(cat config.ign)" --image CoreOS:CoreOS:Alpha:latest
```

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux quickstart guide][quickstart] or dig into [more specific topics][docs].


[azurecli-heading]: #via-the-microsoft-azure-cli
[docs]: https://coreos.com/docs
[quickstart]: quickstart.md
[reboot-docs]: update-strategies.md
[release-notes]: https://coreos.com/releases
[update-docs]: https://coreos.com/why/#updates
[azure-cli]: https://docs.microsoft.com/en-us/cli/azure/overview
[cl-configs]: provisioning.md
