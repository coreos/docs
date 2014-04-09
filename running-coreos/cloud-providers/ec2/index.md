---
layout: docs
title: Amazon EC2
category: running_coreos
sub_category: cloud_provider
weight: 1
cloud-formation-launch-logo: https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png
---
{% capture cf_template %}{{ site.https-s3 }}/dist/aws/coreos-alpha.template{% endcapture %}

# Running CoreOS {{ site.ami-version }} on EC2

The current AMIs for all CoreOS channels and EC2 regions are listed below and updated frequently. Using CloudFormation is the easiest way to launch a cluster, but you can also follow the manual steps at the end of the article. You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Choosing a Channel

CoreOS is designed to be [updated automatically]({{site.url}}/using-coreos/updates) with different schedules per channel. You can [disable this feature]({{site.url}}/docs/cluster-management/debugging/prevent-reboot-after-update), although we don't recommend it. Release notes can currently be found on [Github](https://github.com/coreos/manifest/releases) but we're researching better options.

<div id="ec2-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.url}}/using-coreos/docker">docker</a>, <a href="{{site.url}}/using-coreos/etcd">etcd</a> and <a href="{{site.url}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.ami-version}}.</p>
      </div>
      <table>
        <thead>
          <tr>
            <th>EC2 Region</th>
            <th>AMI ID</th>
            <th>CloudFormation</th>
          </tr>
        </thead>
        <tbody>
      {% assign pairs = site.amis-all | split: "|" %}
      {% for item in pairs %} 

        {% assign amis = item | split: "=" %}
        {% for item in amis limit:1 offset:0 %}
           {% assign region = item %}
        {% endfor %}
        {% for item in amis limit:1 offset:1 %}
           {% assign ami-id = item %}
        {% endfor %}
        {% if region == "us-east-1" %}
          {% assign ami-us-east-1 = ami-id %}
        {% endif %}

        <tr>
          <td>{{ region }}</td>
          <td><a href="https://console.aws.amazon.com/ec2/home?region={{ region }}#launchAmi={{ ami-id }}">{{ ami-id }}</a></td>
          <td><a href="https://console.aws.amazon.com/cloudformation/home?region={{ region }}#cstack=sn%7ECoreOS-alpha%7Cturl%7E{{ cf_template  }}" target="_blank"><img src="{{page.cloud-formation-launch-logo}}" alt="Launch Stack"/></a></td>
        </tr>

      {% endfor %}
        </tbody>
      </table>
    </div>
  </div>
</div>

CloudFormation will launch a cluster of CoreOS machines with a security and autoscaling group.

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config-docs]. You can provide raw cloud-config data to CoreOS via the Amazon web console or [via the EC2 API][ec2-cloud-config]. Our CloudFormation template supports the most common cloud-config options as well.

The most common cloud-config for EC2 looks like:

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

</br>
<div class="row">
  <div class="col-lg-6 col-md-6 col-sm-6 col-xs-12">
    <img src="{{site.url}}/assets/images/media/ec2-cloudformation-cloud-config.png" class="screenshot" />
    <div class="caption">Providing options during CloudFormation.</div>
  </div>
  <div class="col-lg-6 col-md-6 col-sm-6 col-xs-12">
    <img src="{{site.url}}/assets/images/media/ec2-instance-cloud-config.png" class="screenshot" />
    <div class="caption">Providing cloud-config during EC2 boot wizard.</div>
  </div>
</div>

[ec2-cloud-config]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
[cloud-config-docs]: {{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config

### Instance Storage

Ephemeral disks and additional EBS volumes attached to instances can be mounted with a `.mount` unit. Amazon's block storage devices are attached differently [depending on the instance type](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html#InstanceStoreDeviceNames). Here's the cloud-config to mount the first ephemeral disk, `xvdb` on most instance types:

```
#cloud-config
coreos:
  units:
    - name media-ephemeral.mount
      command: start
      content: |
        [Mount]
        What=/dev/xvdb
        Where=/media/ephemeral
        Type=ext3
```

For more information about mounting storage, Amazon's [own documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html) is the best source. You can also read about [mounting storage on CoreOS]({{site.url}}/docs/cluster-management/setup/mounting-storage).

### Adding More Machines
To add more instances to the cluster, just launch more with the same cloud-config, the appropriate security group and the AMI for that region. New instances will join the cluster regardless of region if the security groups are configured correctly.

## Multiple Clusters
If you would like to create multiple clusters you will need to change the "Stack Name". You can find the direct [template file on S3]({{ cf_template }}).

## Manual setup

[us-east-latest-quicklaunch]: https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi={{ami-us-east-1}} "{{ami-us-east-1}}"

**TL;DR:** launch three instances of [{{ami-us-east-1}}][us-east-latest-quicklaunch] in **us-east-1** with a security group that has open port 22, 4001, and 7001 and the same "User Data" of each host. SSH uses the `core` user and you have [etcd][etcd-docs] and [docker][docker-docs] to play with.

### Creating the security group

You need open port 7001 and 4001 between servers in the `etcd` cluster. Step by step instructions below.

_This step is only needed once_

First we need to create a security group to allow CoreOS instances to communicate with one another. 

1. Go to the [security group][sg] page in the EC2 console.
2. Click "Create Security Group"
    * Name: coreos-testing
    * Description: CoreOS instances 
    * VPC: No VPC
    * Click: "Yes, Create"
3. In the details of the security group, click the `Inbound` tab
4. First, create an open rule for SSH
    * Create a new rule: `SSH`
    * Source: 0.0.0.0/0
    * Click: "Add Rule"
5. Add rule for etcd internal communication
    * Create a new rule: `Custom TCP rule`
    * Port range: 7001, 4001
    * Source: type "coreos-testing" until your security group auto-completes. Should be something like "sg-8d4feabc"
    * Click: "Add Rule"
6. Click "Apply Rule Changes"

[sg]: https://console.aws.amazon.com/ec2/home?region=us-east-1#s=SecurityGroups

### Launching a test cluster

We will be launching three instances, with a few parameters in the User Data, and selecting our security group.

1. Open the quick launch by clicking [here][us-east-latest-quicklaunch] (shift+click for new tab)
    * For reference, the current us-east-1 is: [{{ami-us-east-1}}][us-east-latest-quicklaunch]
2. On the second page of the wizard, launch 3 servers to test our clustering
    * Number of instances: 3 
    * Click "Continue"
3. Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at [https://discovery.etcd.io/new](https://discovery.etcd.io/new) and add it to the metadata. You should re-use this key for each machine in the cluster.

```
#cloud-config

coreos:
  etcd:
    discovery_url: https://discovery.etcd.io/<token>
    fleet:
        autostart: yes
```
4. Back in the EC2 dashboard, paste this information verbatim into the "User Data" field. 
   * Paste link into "User Data"
   * "Continue"
5. Storage Configuration
   * "Continue"
6. Tags
   * "Continue"
7. Create Key Pair
   * Choose a key of your choice, it will be added in addition to the one in the gist.
   * "Continue"
8. Choose one or more of your existing Security Groups
   * "coreos-testing" as above.
9. Launch!

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.url}}/docs/quickstart) guide or dig into [more specific topics]({{site.url}}/docs).
