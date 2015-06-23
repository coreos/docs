---
layout: docs
title: Amazon EC2 Container Service
category: running_coreos
sub_category: cloud_provider
supported: true
weight: 1
---

# Running CoreOS with AWS EC2 Container Service

[Amazon EC2 Container Service (ECS)](http://aws.amazon.com/ecs/) is a container management service which provides a set of APIs for scheduling container workloads across EC2 clusters. It supports CoreOS with Docker containers.

Your CoreOS machines communicate with ECS via an agent. The agent interacts with docker to start new containers and gather information about running containers.

## Set Up A New Cluster

When booting your [CoreOS Machines on EC2]({{site.baseurl}}/docs/running-coreos/cloud-providers/ec2), specify that the ECS agent is started via [cloud-config]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config).

Be sure to change `ECS_CLUSTER` to the cluster name you've configured via the ECS CLI or leave it empty for the default. Here's a full cloud-config example:

```yaml
#cloud-config

coreos:
 units:
   -
     name: amazon-ecs-agent.service
     command: start
     runtime: true
     content: |
       [Unit]
       Description=Amazon ECS Agent
       After=docker.service
       Requires=docker.service
       Requires=network-online.target
       After=network-online.target
       
       [Service]
       Environment=ECS_CLUSTER=your_cluster_name
       Environment=ECS_LOGLEVEL=warn
       Environment=ECS_CHECKPOINT=true
       ExecStartPre=-/usr/bin/docker kill ecs-agent
       ExecStartPre=-/usr/bin/docker rm ecs-agent
       ExecStartPre=/usr/bin/docker pull amazon/amazon-ecs-agent
       ExecStart=/usr/bin/docker run --name ecs-agent --env=ECS_CLUSTER=${ECS_CLUSTER} --env=ECS_LOGLEVEL=${ECS_LOGLEVEL} --env=ECS_CHECKPOINT=${ECS_CHECKPOINT} --publish=127.0.0.1:51678:51678 --volume=/var/run/docker.sock:/var/run/docker.sock --volume=/var/lib/aws/ecs:/data amazon/amazon-ecs-agent
       ExecStop=/usr/bin/docker stop ecs-agent
```

The example above pulls the latest official Amazon ECS agent container from the Docker Hub when the machine starts. If you ever need to update the agent, it’s as simple as restarting the amazon-ecs-agent service or the CoreOS machine.

If you want to configure SSH keys in order to log in, mount disks or configure other options, see the [full cloud-config documentation]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config).

## Connect ECS to an Existing Cluster

Connecting an existing cluster to ECS is simple with [fleet]({{site.baseurl}}/docs/launching-containers/launching/launching-containers-fleet) &mdash; the agent can be run as a global unit. The unit looks similar to the example above:

#### amazon-ecs-agent.service

```ini
[Unit]
Description=Amazon ECS Agent
After=docker.service
Requires=docker.service
Requires=network-online.target
After=network-online.target

[Service]
Environment=ECS_CLUSTER=your_cluster_name
Environment=ECS_LOGLEVEL=warn
ExecStartPre=-/usr/bin/docker kill ecs-agent
ExecStartPre=-/usr/bin/docker rm ecs-agent
ExecStartPre=/usr/bin/docker pull amazon/amazon-ecs-agent
ExecStart=/usr/bin/docker run --name ecs-agent --env=ECS_CLUSTER=${ECS_CLUSTER} --env=ECS_LOGLEVEL=${ECS_LOGLEVEL} --publish=127.0.0.1:51678:51678 --volume=/var/run/docker.sock:/var/run/docker.sock amazon/amazon-ecs-agent
ExecStop=/usr/bin/docker stop ecs-agent

[X-Fleet]
Global=true
```

Be sure to change `ECS_CLUSTER` to the cluster name you've configured in the AWS console or leave it empty for the default.

To run this unit on each machine, all you have to do is submit it to the cluster:

```sh
$ fleetctl start amazon-ecs-agent.service
Triggered global unit amazon-ecs-agent.service start
```

You should see all of your machines show up in the ECS CLI output.

For more information on using ECS, check out the [official Amazon documentation](http://aws.amazon.com/documentation/ecs/).
