---
layout: docs
slug: ec2
title: Documentation - Amazon EC2
cloud-formation-launch-logo: https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png
---
{% capture cf_template %}{{ site.https-s3 }}/dist/aws/coreos-alpha.template{% endcapture %}

# Running CoreOS {{ site.ami-version }} on EC2

CoreOS is currently in heavy development and actively being tested. The current AMIs for all EC2 regions are listed below and updated frequently. Each time a new update is released, your machines will [automatically upgrade themselves]({{ site.url }}/using-coreos/updates). Using CloudFormation is the easiest way to launch a cluster, but you can also follow the manual steps at the end of the article.

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

CloudFormation will launch at least three instances with the appropriate security group to enable [etcd]({{ site.url }}/using-coreos/etcd) clustered sharing data between the hosts. You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

### Adding More Machines
To add more instances to the cluster, just launch more with the same user-data, the appropriate security group and the AMI for that region. New instances will join the cluster regardless of region if the security groups are configured correctly.

### Multiple Clusters
If you would like to create multiple clusters you will need to change the "Stack Name". You can find the direct [template file on S3]({{ cf_template }}).

## Manual setup

[us-east-latest-quicklaunch]: https://console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi={{ami-us-east-1}} "{{ami-us-east-1}}"

**TL;DR:** launch three instances of [{{ami-us-east-1}}][us-east-latest-quicklaunch] in **us-east-1** with a security group that has open port 22, 4001, and 7001 and the same random token in the "User Data" of each host. SSH uses the `core` user and you have [etcd][etcd-docs] and [docker][docker-docs] to play with.

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

We will be launching three instances, with a shared token (via a gist url) in the User Data, and selecting our security group.

1. Open the quick launch by clicking [here][us-east-latest-quicklaunch] (shift+click for new tab)
    * For reference, the current us-east-1 is: [{{ site.ami-us-east-1 }}][ec2-us-east-1]
2. On the second page of the wizard, launch 3 servers to test our clustering
    * Number of instances: 3 
    * Click "Continue"
3. Next, we need a secret shared token for user-data. This will be used to bootstrap the cluster. This needs to be a reasonably long secret key. We like using gist for this, since each gist url is public but unique. 
   * Open [gist.github.com](https://gist.github.com)
   * Optional: If you paste in your public ssh key to the gist, it will automatically be added to your `core` users ssh client list. 
   * Click "Create secret gist"
   * Copy the gist url to your clipboard. 
4. Back in the EC2 dashboard, paste this URL verbatim into the "User Data" field. 
   * Paste "https://gist..." link into "User Data"
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

Now that you have a few machines booted it is time to play around. Check out the [Using CoreOS][using-coreos] guide.
