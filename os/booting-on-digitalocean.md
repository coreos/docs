# Running CoreOS Container Linux on DigitalOcean

## Choosing a channel

Container Linux is designed to be [updated automatically][update-docs] with different schedules per channel. You can [disable this feature][reboot-docs], although we don't recommend it. Read the [release notes][release-notes] for specific features and bug fixes.

The following command will create a single droplet. For more details, check out [Launching via the API](#via-the-api).

<div id="do-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
        <a href="https://cloud.digitalocean.com/droplets/new?image=coreos-alpha" class="btn btn-default">Launch Container Linux Droplet</a><br/><br/>
        <p>Launch via DigitalOcean API by specifying <code>$REGION</code>, <code>$SIZE</code> and <code>$SSH_KEY_ID</code>:</p>
        <pre>curl --request POST "https://api.digitalocean.com/v2/droplets" \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $TOKEN" \
     --data '{"region":"'"${REGION}"'",
        "image":"{{site.data.alpha-channel.do-image-path}}",
        "size":"'"$SIZE"'",
        "user_data": "'"$(cat ~/config.ign)"'",
        "ssh_keys":["'"$SSH_KEY_ID"'"],
        "name":"core-1"}'</pre>
      </div>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
        <a href="https://cloud.digitalocean.com/droplets/new?image=coreos-beta" class="btn btn-default">Launch Container Linux Droplet</a><br/><br/>
        <p>Launch via DigitalOcean API by specifying <code>$REGION</code>, <code>$SIZE</code> and <code>$SSH_KEY_ID</code>:</p>
        <pre>curl --request POST "https://api.digitalocean.com/v2/droplets" \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $TOKEN" \
     --data '{"region":"'"${REGION}"'",
        "image":"{{site.data.beta-channel.do-image-path}}",
        "size":"'"$SIZE"'",
        "user_data": "'"$(cat ~/config.ign)"'",
        "ssh_keys":["'"$SSH_KEY_ID"'"],
        "name":"core-1"}'</pre>
      </div>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
        <a href="https://cloud.digitalocean.com/droplets/new?image=coreos-stable" class="btn btn-default">Launch Container Linux Droplet</a><br/><br/>
        <p>Launch via DigitalOcean API by specifying <code>$REGION</code>, <code>$SIZE</code> and <code>$SSH_KEY_ID</code>:</p>
        <pre>curl --request POST "https://api.digitalocean.com/v2/droplets" \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $TOKEN" \
     --data '{"region":"'"${REGION}"'",
        "image":"{{site.data.stable-channel.do-image-path}}",
        "size":"'"$SIZE"'",
        "user_data": "'"$(cat ~/config.ign)"'",
        "ssh_keys":["'"$SSH_KEY_ID"'"],
        "name":"core-1"}'</pre>
      </div>
      </div>
    </div>
  </div>
</div>

[update-docs]: https://coreos.com/why/#updates
[reboot-docs]: update-strategies.md
[release-notes]: https://coreos.com/releases

## Ignition config

Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Ignition. Head over to the [docs to learn about the supported features][ignition-docs]. Note that DigitalOcean doesn't allow an instance's userdata to be modified after the instance has been launched. This isn't a problem since Ignition only runs on the first boot.

You can provide a raw Ignition config to Container Linux via the DigitalOcean web console or [via the DigitalOcean API](#via-the-api).

As an example, this config will configure and start etcd:

```container-linux-config
systemd:
  units:
    - name: etcd2.service
      enable: true
      dropins:
        - name: metadata.conf
          contents: |
            [Unit]
            Requires=coreos-metadata.service
            After=coreos-metadata.service

            [Service]
            EnvironmentFile=/run/metadata/coreos
            ExecStart=
            ExecStart=/usr/bin/etcd2 \
                --advertise-client-urls=http://${COREOS_DIGITALOCEAN_IPV4_PRIVATE_0}:2379 \
                --initial-advertise-peer-urls=http://${COREOS_DIGITALOCEAN_IPV4_PRIVATE_0}:2380 \
                --listen-client-urls=http://0.0.0.0:2379 \
                --listen-peer-urls=http://${COREOS_DIGITALOCEAN_IPV4_PRIVATE_0}:2380 \
                --discovery=https://discovery.etcd.io/<token>
```

[ignition-docs]: https://coreos.com/ignition/docs/latest

### Adding more machines

To add more instances to the cluster, just launch more with the same Ignition config. New instances will join the cluster regardless of region.

## SSH to your droplets

Container Linux is set up to be a little more secure than other DigitalOcean images. By default, it uses the core user instead of root and doesn't use a password for authentication. You'll need to add an SSH key(s) via the web console or add keys/passwords via your Ignition config in order to log in.

To connect to a droplet after it's created, run:

```sh
ssh core@<ip address>
```

Optionally, you may want to [configure your ssh-agent](https://github.com/coreos/fleet/blob/master/Documentation/using-the-client.md#remote-fleet-access) to more easily run [fleet commands](../fleet/launching-containers-fleet.md).

## Launching droplets

### Via the API

For starters, generate a [Personal Access Token][do-token-settings] and save it in an environment variable:

```sh
read TOKEN
# Enter your Personal Access Token
```

Upload your SSH key via [DigitalOcean's API][do-keys-docs] or the web console. Retrieve the SSH key ID via the ["list all keys"][do-list-keys-docs] method:

```sh
curl --request GET "https://api.digitalocean.com/v2/account/keys" \
     --header "Authorization: Bearer $TOKEN"
```

Save the key ID from the previous command in an environment variable:

```sh
read SSH_KEY_ID
# Enter your SSH key ID
```

Create a 512MB droplet with private networking in NYC3 from the Container Linux Stable image:

```sh
curl --request POST "https://api.digitalocean.com/v2/droplets" \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $TOKEN" \
     --data '{
      "region":"nyc3",
      "image":"{{site.data.stable-channel.do-image-path}}",
      "size":"512mb",
      "name":"core-1",
      "private_networking":true,
      "ssh_keys":['$SSH_KEY_ID'],
      "user_data": "'"$(cat config.ign | sed 's/"/\\"/g')"'"
}'

```

For more details, check out [DigitalOcean's API documentation][do-api-docs].

[do-api-docs]: https://developers.digitalocean.com/#droplets
[do-keys-docs]: https://developers.digitalocean.com/#keys
[do-list-keys-docs]: https://developers.digitalocean.com/#list-all-keys
[do-token-settings]: https://cloud.digitalocean.com/settings/applications

### Via the web console

1. Open the ["new droplet"](https://cloud.digitalocean.com/droplets/new?image=coreos-stable) page in the web console.
2. Give the machine a hostname, select the size, and choose a region.
<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12 co-m-screenshot">
    <img src="img/size.png" />
    <div class="co-m-screenshot-caption">Choosing a size and hostname</div>
  </div>
</div>
3. Enable User Data and add your Ignition config in the text box.
<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12 co-m-screenshot">
    <img src="img/settings.png" />
    <div class="co-m-screenshot-caption">Droplet settings for networking and cloud-config</div>
  </div>
</div>
4. Choose your [preferred channel](#choosing-a-channel) of Container Linux.
<div class="row">
  <div class="col-lg-8 col-md-10 col-sm-8 col-xs-12 co-m-screenshot">
    <img src="img/image.png" />
    <div class="co-m-screenshot-caption">Choosing a Container Linux channel</div>
  </div>
</div>
5. Select your SSH keys.

Note that DigitalOcean is not able to inject a root password into Container Linux images like it does with other images. You'll need to add your keys via the web console or add keys or passwords via your Ignition config in order to log in.

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux Quickstart][quick-start] guide or dig into [more specific topics][docs].

[quick-start]: quickstart.md
[docs]: https://coreos.com/docs
