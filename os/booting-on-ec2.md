
{% capture cf_alpha_pv_template %}{{ site.https-s3 }}/dist/aws/coreos-alpha-pv.template{% endcapture %}
{% capture cf_alpha_hvm_template %}{{ site.https-s3 }}/dist/aws/coreos-alpha-hvm.template{% endcapture %}
{% capture cf_beta_pv_template %}{{ site.https-s3 }}/dist/aws/coreos-beta-pv.template{% endcapture %}
{% capture cf_beta_hvm_template %}{{ site.https-s3 }}/dist/aws/coreos-beta-hvm.template{% endcapture %}
{% capture cf_stable_pv_template %}{{ site.https-s3 }}/dist/aws/coreos-stable-pv.template{% endcapture %}
{% capture cf_stable_hvm_template %}{{ site.https-s3 }}/dist/aws/coreos-stable-hvm.template{% endcapture %}

# Running CoreOS on EC2

The current AMIs for all CoreOS channels and EC2 regions are listed below and updated frequently. Using CloudFormation is the easiest way to launch a cluster, but you can also follow the manual steps at the end of the article. You can direct questions to the [IRC channel][irc] or [mailing list][coreos-dev].

## Choosing a Channel

CoreOS is designed to be [updated automatically]({{site.baseurl}}/using-coreos/updates) with different schedules per channel. You can [disable this feature]({{site.baseurl}}/docs/cluster-management/debugging/prevent-reboot-after-update), although we don't recommend it. Read the [release notes]({{site.baseurl}}/releases) for specific features and bug fixes.

<div id="ec2-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The alpha channel closely tracks master and is released to frequently. The newest versions of <a href="{{site.baseurl}}/using-coreos/docker">docker</a>, <a href="{{site.baseurl}}/using-coreos/etcd">etcd</a> and <a href="{{site.baseurl}}/using-coreos/clustering">fleet</a> will be available for testing. Current version is CoreOS {{site.alpha-channel}}.</p>
        <a class="btn btn-link btn-icon-left co-p-docs-rss" href="{{site.baseurl}}/dist/aws/aws-alpha.json"><span class="fa fa-rss"></span>View as json feed</a>
      </div>
      <table>
        <thead>
          <tr>
            <th>EC2 Region</th>
            <th>AMI Type</th>
            <th>AMI ID</th>
            <th>CloudFormation</th>
          </tr>
        </thead>
        <tbody>
        {% for region in site.data.alpha-channel.amis %}
	{% capture region_domain %}{% if region.name == 'us-gov-west-1' %}amazonaws-us-gov.com{% else %}aws.amazon.com{% endif %}{% endcapture %}
        <tr>
          <td rowspan="2">{{ region.name }}</td>
          <td class="dashed"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">PV</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.pv }}">{{ region.pv }}</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/cloudformation/home?region={{ region.name }}#cstack=sn%7ECoreOS-alpha%7Cturl%7E{{ cf_alpha_pv_template  }}" target="_blank"><img src="{{page.cloud-formation-launch-logo}}" alt="Launch Stack"/></a></td>
        </tr>
        <tr>
          <td class="rowspan-padding"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          <td><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.hvm }}">{{ region.hvm }}</a></td>
          <td><a href="https://console.{{ region_domain }}/cloudformation/home?region={{ region.name }}#cstack=sn%7ECoreOS-alpha%7Cturl%7E{{ cf_alpha_hvm_template  }}" target="_blank"><img src="{{page.cloud-formation-launch-logo}}" alt="Launch Stack"/></a></td>
        </tr>
        {% endfor %}
        </tbody>
      </table>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The beta channel consists of promoted alpha releases. Current version is CoreOS {{site.beta-channel}}.</p>
        <a class="btn btn-link btn-icon-left co-p-docs-rss" href="{{site.baseurl}}/dist/aws/aws-beta.json"><span class="fa fa-rss"></span>View as json feed</a>
      </div>
      <table>
        <thead>
          <tr>
            <th>EC2 Region</th>
            <th>AMI Type</th>
            <th>AMI ID</th>
            <th>CloudFormation</th>
          </tr>
        </thead>
        <tbody>
        {% for region in site.data.beta-channel.amis %}
	{% capture region_domain %}{% if region.name == 'us-gov-west-1' %}amazonaws-us-gov.com{% else %}aws.amazon.com{% endif %}{% endcapture %}
        <tr>
          <td rowspan="2">{{ region.name }}</td>
          <td class="dashed"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">PV</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.pv }}">{{ region.pv }}</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/cloudformation/home?region={{ region.name }}#cstack=sn%7ECoreOS-beta%7Cturl%7E{{ cf_beta_pv_template  }}" target="_blank"><img src="{{page.cloud-formation-launch-logo}}" alt="Launch Stack"/></a></td>
        </tr>
        <tr>
          <td class="rowspan-padding"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          <td><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.hvm }}">{{ region.hvm }}</a></td>
          <td><a href="https://console.{{ region_domain }}/cloudformation/home?region={{ region.name }}#cstack=sn%7ECoreOS-beta%7Cturl%7E{{ cf_beta_hvm_template  }}" target="_blank"><img src="{{page.cloud-formation-launch-logo}}" alt="Launch Stack"/></a></td>
        </tr>
        {% endfor %}
        </tbody>
      </table>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of CoreOS are battle-tested within the Beta and Alpha channels before being promoted. Current version is CoreOS {{site.stable-channel}}.</p>
        <a class="btn btn-link btn-icon-left co-p-docs-rss" href="{{site.baseurl}}/dist/aws/aws-stable.json"><span class="fa fa-rss"></span>View as json feed</a>
      </div>
      <table>
        <thead>
          <tr>
            <th>EC2 Region</th>
            <th>AMI Type</th>
            <th>AMI ID</th>
            <th>CloudFormation</th>
          </tr>
        </thead>
        <tbody>
        {% for region in site.data.stable-channel.amis %}
	{% capture region_domain %}{% if region.name == 'us-gov-west-1' %}amazonaws-us-gov.com{% else %}aws.amazon.com{% endif %}{% endcapture %}
        <tr>
          <td rowspan="2">{{ region.name }}</td>
          <td class="dashed"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">PV</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.pv }}">{{ region.pv }}</a></td>
          <td class="dashed"><a href="https://console.{{ region_domain }}/cloudformation/home?region={{ region.name }}#cstack=sn%7ECoreOS-stable%7Cturl%7E{{ cf_stable_pv_template  }}" target="_blank"><img src="{{page.cloud-formation-launch-logo}}" alt="Launch Stack"/></a></td>
        </tr>
        <tr>
          <td class="rowspan-padding"><a href="http://aws.amazon.com/amazon-linux-ami/instance-type-matrix/">HVM</a></td>
          <td><a href="https://console.{{ region_domain }}/ec2/home?region={{ region.name }}#launchAmi={{ region.hvm }}">{{ region.hvm }}</a></td>
          <td><a href="https://console.{{ region_domain }}/cloudformation/home?region={{ region.name }}#cstack=sn%7ECoreOS-stable%7Cturl%7E{{ cf_stable_hvm_template  }}" target="_blank"><img src="{{page.cloud-formation-launch-logo}}" alt="Launch Stack"/></a></td>
        </tr>
        {% endfor %}
        </tbody>
      </table>
    </div>
  </div>
</div>

CloudFormation will launch a cluster of CoreOS machines with a security and autoscaling group.

## Cloud-Config

CoreOS allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config-docs]. Cloud-config is intended to bring up a cluster of machines into a minimal useful state and ideally shouldn't be used to configure anything that isn't standard across many hosts. Once a machine is created on EC2, the cloud-config can only be modified after it is stopped or recreated.

You can provide raw cloud-config data to CoreOS via the Amazon web console or [via the EC2 API][ec2-cloud-config]. Our CloudFormation template supports the most common cloud-config options as well.

The most common cloud-config for EC2 looks like:

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
    listen-peer-urls: http://$private_ipv4:2380,http://$private_ipv4:7001
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
```

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on EC2.

</br>
<div class="row">
  <div class="col-lg-6 col-md-6 col-sm-6 col-xs-12 co-m-screenshot">
    <a href="{{site.baseurl}}/assets/images/media/ec2-cloudformation-cloud-config.png">
      <img src="{{site.baseurl}}/assets/images/media/ec2-cloudformation-cloud-config.png" />
    </a>
    <div class="co-m-screenshot-caption">Providing options during CloudFormation.</div>
  </div>
  <div class="col-lg-6 col-md-6 col-sm-6 col-xs-12 co-m-screenshot">
    <a href="{{site.baseurl}}/assets/images/media/ec2-instance-cloud-config.png">
      <img src="{{site.baseurl}}/assets/images/media/ec2-instance-cloud-config.png" class="screenshot" />
    </a>
    <div class="co-m-screenshot-caption">Providing cloud-config during EC2 boot wizard.</div>
  </div>
</div>

[ec2-cloud-config]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
[cloud-config-docs]: {{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config

### Instance Storage

Ephemeral disks and additional EBS volumes attached to instances can be mounted with a `.mount` unit. Amazon's block storage devices are attached differently [depending on the instance type](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html#InstanceStoreDeviceNames). Here's the cloud-config to mount the first ephemeral disk, `xvdb` on most instance types:

```yaml
#cloud-config
coreos:
  units:
    - name: media-ephemeral.mount
      command: start
      content: |
        [Mount]
        What=/dev/xvdb
        Where=/media/ephemeral
        Type=ext3
```

For more information about mounting storage, Amazon's [own documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html) is the best source. You can also read about [mounting storage on CoreOS]({{site.baseurl}}/docs/cluster-management/setup/mounting-storage).

### Adding More Machines
To add more instances to the cluster, just launch more with the same cloud-config, the appropriate security group and the AMI for that region. New instances will join the cluster regardless of region if the security groups are configured correctly.

## SSH to your Instances

CoreOS is set up to be a little more secure than other cloud images. By default, it uses the `core` user instead of `root` and doesn't use a password for authentication. You'll need to add an SSH key(s) via the AWS console or add keys/passwords via your cloud-config in order to log in.

To connect to an instance after it's created, run:

```sh
ssh core@<ip address>
```

Optionally, you may want to [configure your ssh-agent]({{site.baseurl}}/docs/launching-containers/launching/fleet-using-the-client/#remote-fleet-access) to more easily run [fleet commands]({{site.baseurl}}/docs/launching-containers/launching/launching-containers-fleet/).

## Multiple Clusters
If you would like to create multiple clusters you will need to change the "Stack Name". You can find the direct [template file on S3]({{ cf_beta_pv_template }}).

## Manual setup

{% for region in site.data.alpha-channel.amis %}
  {% if region.name == 'us-east-1' %}
**TL;DR:** launch three instances of [{{region.pv}}](https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.pv}}) in **{{region.name}}** with a security group that has open port 22, 2379, 2380, 4001, and 7001 and the same "User Data" of each host. SSH uses the `core` user and you have [etcd][etcd-docs] and [docker][docker-docs] to play with.
  {% endif %}
{% endfor %}

### Creating the security group

You need open port 2379, 2380, 7001 and 4001 between servers in the `etcd` cluster. Step by step instructions below.

_This step is only needed once_

First we need to create a security group to allow CoreOS instances to communicate with one another. 

1. Go to the [security group][sg] page in the EC2 console.
2. Click "Create Security Group"
    * Name: coreos-testing
    * Description: CoreOS instances 
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
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.pv}}" target="_blank">quick launch wizard</a> to boot {{region.pv}}.
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
          Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at <a href="https://discovery.etcd.io/new">https://discovery.etcd.io/new</a> and add it to the metadata. You should re-use this key for each machine in the cluster.
        </li>
        <pre>
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
    listen-peer-urls: http://$private_ipv4:2380,http://$private_ipv4:7001
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
</pre>
        <li>
          Back in the EC2 dashboard, paste this information verbatim into the "User Data" field. 
          <ul>
            <li>Paste link into "User Data"</li>
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
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.pv}}" target="_blank">quick launch wizard</a> to boot {{region.pv}}.
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
          Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at <a href="https://discovery.etcd.io/new">https://discovery.etcd.io/new</a> and add it to the metadata. You should re-use this key for each machine in the cluster.
        </li>
        <pre>
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
    listen-peer-urls: http://$private_ipv4:2380,http://$private_ipv4:7001
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
</pre>
        <li>
          Back in the EC2 dashboard, paste this information verbatim into the "User Data" field. 
          <ul>
            <li>Paste link into "User Data"</li>
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
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.pv}}" target="_blank">quick launch wizard</a> to boot {{region.pv}}.
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
        <pre>
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
    listen-peer-urls: http://$private_ipv4:2380,http://$private_ipv4:7001
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
</pre>
        <li>
          Back in the EC2 dashboard, paste this information verbatim into the "User Data" field. 
          <ul>
            <li>Paste link into "User Data"</li>
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

### Automatic Rollback Limitations on EC2

Amazon EC2 uses Xen paravirtualization which is incompatible with kexec.  CoreOS uses this to rollback a bad update by simply rebooting the virtual machine.

## Using CoreOS

Now that you have a machine booted it is time to play around.
Check out the [CoreOS Quickstart]({{site.baseurl}}/docs/quickstart) guide or dig into [more specific topics]({{site.baseurl}}/docs).
