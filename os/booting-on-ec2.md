# Running CoreOS Container Linux on EC2

The current AMIs for all Container Linux channels and EC2 regions are listed below and updated frequently. Questions can be directed to the CoreOS [IRC channel][irc] or [user mailing list][coreos-user].

## Choosing a channel

Container Linux is designed to be [updated automatically](https://coreos.com/why/#updates) with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://coreos.com/releases) for specific features and bug fixes.

<div id="ec2-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Container Linux {{site.alpha-channel}}.</p>
        <a class="btn btn-link btn-icon-left co-p-docs-rss" href="https://coreos.com/dist/aws/aws-alpha.json"><span class="fa fa-rss"></span>View as json feed</a>
      </div>
      <table>
        <thead>
          <tr>
            <th>EC2 Region</th>
            <th>AMI Type</th>
            <th>AMI ID</th>
          </tr>
        </thead>
        <tbody>
        {% for region in site.data.alpha-channel.amis %}
        {% capture region_domain %}{% if region.name == 'us-gov-west-1' %}amazonaws-us-gov.com{% elsif region.name == 'cn-north-1' or region.name == 'cn-northwest-1' %}amazonaws.cn{% else %}aws.amazon.com{% endif %}{% endcapture %}
        {% if region.pv %}
        <tr>
          <td rowspan="2">{{ region.name }}</td>
          <td class="dashed"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">PV</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.pv }}">{{ region.pv }}</a></td>
        </tr>
        {% endif %}
        <tr>
          {% unless region.pv %}
          <td>{{ region.name }}</td>
          <td><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          {% else %}
          <td class="rowspan-padding"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          {% endunless %}
          <td><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.hvm }}">{{ region.hvm }}</a></td>
        </tr>
        {% endfor %}
        </tbody>
      </table>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Container Linux {{site.beta-channel}}.</p>
        <a class="btn btn-link btn-icon-left co-p-docs-rss" href="https://coreos.com/dist/aws/aws-beta.json"><span class="fa fa-rss"></span>View as json feed</a>
      </div>
      <table>
        <thead>
          <tr>
            <th>EC2 Region</th>
            <th>AMI Type</th>
            <th>AMI ID</th>
          </tr>
        </thead>
        <tbody>
        {% for region in site.data.beta-channel.amis %}
        {% capture region_domain %}{% if region.name == 'us-gov-west-1' %}amazonaws-us-gov.com{% elsif region.name == 'cn-north-1' or region.name == 'cn-northwest-1' %}amazonaws.cn{% else %}aws.amazon.com{% endif %}{% endcapture %}
        {% if region.pv %}
        <tr>
          <td rowspan="2">{{ region.name }}</td>
          <td class="dashed"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">PV</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.pv }}">{{ region.pv }}</a></td>
        </tr>
        {% endif %}
        <tr>
          {% unless region.pv %}
          <td>{{ region.name }}</td>
          <td><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          {% else %}
          <td class="rowspan-padding"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          {% endunless %}
          <td><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.hvm }}">{{ region.hvm }}</a></td>
        </tr>
        {% endfor %}
        </tbody>
      </table>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Container Linux {{site.stable-channel}}.</p>
        <a class="btn btn-link btn-icon-left co-p-docs-rss" href="https://coreos.com/dist/aws/aws-stable.json"><span class="fa fa-rss"></span>View as json feed</a>
      </div>
      <table>
        <thead>
          <tr>
            <th>EC2 Region</th>
            <th>AMI Type</th>
            <th>AMI ID</th>
          </tr>
        </thead>
        <tbody>
        {% for region in site.data.stable-channel.amis %}
        {% capture region_domain %}{% if region.name == 'us-gov-west-1' %}amazonaws-us-gov.com{% elsif region.name == 'cn-north-1' or region.name == 'cn-northwest-1' %}amazonaws.cn{% else %}aws.amazon.com{% endif %}{% endcapture %}
        {% if region.pv %}
        <tr>
          <td rowspan="2">{{ region.name }}</td>
          <td class="dashed"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">PV</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.pv }}">{{ region.pv }}</a></td>
        </tr>
        {% endif %}
        <tr>
          {% unless region.pv %}
          <td>{{ region.name }}</td>
          <td><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          {% else %}
          <td class="rowspan-padding"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          {% endunless %}
          <td><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.hvm }}">{{ region.hvm }}</a></td>
        </tr>
        {% endfor %}
        </tbody>
      </table>
    </div>
  </div>
</div>

## Container Linux Configs

Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs. These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs].

You can provide a raw Ignition config to Container Linux via the Amazon web console or [via the EC2 API][ec2-user-data].

As an example, this Container Linux Config will configure and start etcd:

```yaml container-linux-config:ec2
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

[ec2-user-data]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
[cl-configs]: provisioning.md

### Instance storage

Ephemeral disks and additional EBS volumes attached to instances can be mounted with a `.mount` unit. Amazon's block storage devices are attached differently [depending on the instance type](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html#InstanceStoreDeviceNames). Here's the Container Linux Config to format and mount the first ephemeral disk, `xvdb`, on most instance types:

```yaml container-linux-config:ec2
storage:
  filesystems:
    - mount:
        device: /dev/xvdb
        format: ext4
        wipe_filesystem: true

systemd:
  units:
    - name: media-ephemeral.mount
      enable: true
      contents: |
        [Mount]
        What=/dev/xvdb
        Where=/media/ephemeral
        Type=ext4

        [Install]
        RequiredBy=local-fs.target
```

For more information about mounting storage, Amazon's [own documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html) is the best source. You can also read about [mounting storage on Container Linux](mounting-storage.md).

### Adding more machines

To add more instances to the cluster, just launch more with the same Container Linux Config, the appropriate security group and the AMI for that region. New instances will join the cluster regardless of region if the security groups are configured correctly.

## SSH to your instances

Container Linux is set up to be a little more secure than other cloud images. By default, it uses the `core` user instead of `root` and doesn't use a password for authentication. You'll need to add an SSH key(s) via the AWS console or add keys/passwords via your Container Linux Config in order to log in.

To connect to an instance after it's created, run:

```sh
ssh core@<ip address>
```

## Multiple clusters
If you would like to create multiple clusters you will need to change the "Stack Name". You can find the direct [template file on S3](https://s3.amazonaws.com/coreos.com/dist/aws/coreos-stable-hvm.template).

## Manual setup

{% for region in site.data.alpha-channel.amis %}
  {% if region.name == 'us-east-1' %}
**TL;DR:** launch three instances of [{{region.hvm}}](https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.hvm}}) in **{{region.name}}** with a security group that has open port 22, 2379, 2380, 4001, and 7001 and the same "User Data" of each host. SSH uses the `core` user and you have [etcd][etcd-docs] and [Docker][docker-docs] to play with.
  {% endif %}
{% endfor %}

### Creating the security group

You need open port 2379, 2380, 7001 and 4001 between servers in the `etcd` cluster. Step by step instructions below.

_This step is only needed once_

First we need to create a security group to allow Container Linux instances to communicate with one another.

1. Go to the [security group][sg] page in the EC2 console.
2. Click "Create Security Group"
    * Name: coreos-testing
    * Description: Container Linux instances
    * VPC: No VPC
    * Click: "Yes, Create"
3. In the details of the security group, click the `Inbound` tab
4. First, create a security group rule for SSH
    * Create a new rule: `SSH`
    * Source: 0.0.0.0/0
    * Click: "Add Rule"
5. Add two security group rules for etcd communication
    * Create a new rule: `Custom TCP rule`
    * Port range: 2379
    * Source: type "coreos-testing" until your security group auto-completes. Should be something like "sg-8d4feabc"
    * Click: "Add Rule"
    * Repeat this process for port range 2380, 4001 and 7001 as well
6. Click "Apply Rule Changes"

[sg]: https://console.aws.amazon.com/ec2/home?region=us-east-1#s=SecurityGroups

### Launching a test cluster

<div id="ec2-manual">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-manual" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-manual" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-manual" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-manual">
      <p>We will be launching three instances, with a few parameters in the User Data, and selecting our security group.</p>
      <ol>
        <li>
        {% for region in site.data.alpha-channel.amis %}
          {% if region.name == 'us-east-1' %}
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.hvm}}" target="_blank">quick launch wizard</a> to boot {{region.hvm}}.
          {% endif %}
        {% endfor %}
        </li>
        <li>
          On the second page of the wizard, launch 3 servers to test our clustering
          <ul>
            <li>Number of instances: 3</li>
            <li>Click "Continue"</li>
          </ul>
        </li>
        <li>
          Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at <a href="https://discovery.etcd.io/new?size=3">https://discovery.etcd.io/new?size=3</a>, configure the `?size=` to your initial cluster size and add it to the metadata. You should re-use this key for each machine in the cluster.
        </li>
        <li>
          Use <a href="provisioning.md">ct</a> to convert the following configuration into an Ignition config, and back in the EC2 dashboard, paste it into the "User Data" field.
          ```yaml container-linux-config:ec2
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
          <ul>
            <li>Paste configuration into "User Data"</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Storage Configuration
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Tags
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Create Key Pair
          <ul>
            <li>Choose a key of your choice, it will be added in addition to the one in the gist.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Choose one or more of your existing Security Groups
          <ul>
            <li>"coreos-testing" as above.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Launch!
        </li>
      </ol>
    </div>
    <div class="tab-pane" id="beta-manual">
      <p>We will be launching three instances, with a few parameters in the User Data, and selecting our security group.</p>
      <ol>
        <li>
        {% for region in site.data.beta-channel.amis %}
          {% if region.name == 'us-east-1' %}
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.hvm}}" target="_blank">quick launch wizard</a> to boot {{region.hvm}}.
          {% endif %}
        {% endfor %}
        </li>
        <li>
          On the second page of the wizard, launch 3 servers to test our clustering
          <ul>
            <li>Number of instances: 3</li>
            <li>Click "Continue"</li>
          </ul>
        </li>
        <li>
          Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at <a href="https://discovery.etcd.io/new?size=3">https://discovery.etcd.io/new?size=3</a>, configure the `?size=` to your initial cluster size and add it to the metadata. You should re-use this key for each machine in the cluster.
        </li>
        <li>
          Use <a href="provisioning.md">ct</a> to convert the following configuration into an Ignition config, and back in the EC2 dashboard, paste it into the "User Data" field.
          ```yaml container-linux-config:ec2
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
          <ul>
            <li>Paste configuration into "User Data"</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Storage Configuration
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Tags
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Create Key Pair
          <ul>
            <li>Choose a key of your choice, it will be added in addition to the one in the gist.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Choose one or more of your existing Security Groups
          <ul>
            <li>"coreos-testing" as above.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Launch!
        </li>
      </ol>
    </div>
    <div class="tab-pane active" id="stable-manual">
      <p>We will be launching three instances, with a few parameters in the User Data, and selecting our security group.</p>
      <ol>
        <li>
        {% for region in site.data.stable-channel.amis %}
          {% if region.name == 'us-east-1' %}
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.hvm}}" target="_blank">quick launch wizard</a> to boot {{region.hvm}}.
          {% endif %}
        {% endfor %}
        </li>
        <li>
          On the second page of the wizard, launch 3 servers to test our clustering
          <ul>
            <li>Number of instances: 3</li>
            <li>Click "Continue"</li>
          </ul>
        </li>
        <li>
          Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at <a href="https://discovery.etcd.io/new?size=3">https://discovery.etcd.io/new?size=3</a>, configure the `?size=` to your initial cluster size and add it to the metadata. You should re-use this key for each machine in the cluster.
        </li>
        <li>
          Use <a href="provisioning.md">ct</a> to convert the following configuration into an Ignition config, and back in the EC2 dashboard, paste it into the "User Data" field.
          ```yaml container-linux-config:ec2
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
          <ul>
            <li>Paste configuration into "User Data"</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Storage Configuration
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Tags
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Create Key Pair
          <ul>
            <li>Choose a key of your choice, it will be added in addition to the one in the gist.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Choose one or more of your existing Security Groups
          <ul>
            <li>"coreos-testing" as above.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Launch!
        </li>
      </ol>
    </div>
  </div>
</div>

## Using CoreOS Container Linux

Now that you have a machine booted it is time to play around. Check out the [Container Linux Quickstart](quickstart.md) guide or dig into [more specific topics](https://coreos.com/docs).


[coreos-user]: https://groups.google.com/forum/#!forum/coreos-user
[docker-docs]: https://docs.docker.io
[etcd-docs]: https://github.com/coreos/etcd/tree/master/Documentation
[irc]: irc://irc.freenode.org:6667/#coreos
