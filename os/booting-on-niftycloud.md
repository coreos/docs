# Running CoreOS on NIFTY Cloud

NIFTY Cloud is a Japanese cloud computing provider. These instructions are also [available in Japanese](booting-on-niftycloud-JA_JP.md). Before proceeding, you will need to [install NIFTY Cloud CLI][cli-documentation].

[cli-documentation]: https://translate.google.com/translate?hl=en&sl=ja&tl=en&u=http%3A%2F%2Fcloud.nifty.com%2Fapi%2Fcli%2F

## Cloud-config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md). Cloud-config is intended to bring up a cluster of machines into a minimal useful state and ideally shouldn't be used to configure anything that isn't standard across many hosts. On NIFTY Cloud, the cloud-config can be modified while the instance is running and will be processed next time the machine boots.

You can provide cloud-config to CoreOS via [NIFTY Cloud CLI][cli-documentation].

The most common cloud-config for NIFTY Cloud looks like:

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

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on NIFTY Cloud.

## Choosing a channel

CoreOS is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

<div id="niftycloud-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
      <p>Launch via NIFTY Cloud CLI by specifying <code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>:</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Alpha {{site.alpha-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml -q POST</pre>
    </div>
    <div class="tab-pane" id="beta">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
      <p>Launch via NIFTY Cloud CLI by specifying <code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>:</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Beta {{site.beta-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml -q POST</pre>
    </div>
    <div class="tab-pane active" id="stable">
      <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
      <p>Launch via NIFTY Cloud CLI by specifying <code>$ZONE</code>, <code>$TYPE</code>, <code>$FW_ID</code> and <code>$SSH_KEY_ID</code>:</p>
      <pre>nifty-run-instances $(nifty-describe-images --delimiter ',' --image-name "CoreOS Stable {{site.stable-channel}}" | awk -F',' '{print $2}') --key $SSH_KEY_ID --availability-zone $ZONE --instance-type $TYPE -g $FW_ID -f cloud-config.yml -q POST</pre>
    </div>
  </div>
</div>

### Adding more machines

To add more instances to the cluster, just launch more with the same cloud-config and the appropriate firewall group.

## SSH

You can log in your CoreOS instances using:

```sh
ssh core@<ip address> -i <path to keyfile>
```

## Using CoreOS

Now that you have a machine booted it is time to play around. Check out the [CoreOS Quickstart](quickstart.md) guide or dig into [more specific topics](https://coreos.com/docs).
