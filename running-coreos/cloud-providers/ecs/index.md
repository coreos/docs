---
layout: docs
title: Amazon EC2 Container Service
category: running_coreos
sub_category: cloud_provider
supported: true
weight: 1
---

# Amazon ECS on CoreOS

At re:Invent 2014, AWS launched [Amazon EC2 Container Service (ECS)](http://aws.amazon.com/ecs/). ECS is a container management service which provides a set of APIs for scheduling container workloads across EC2 clusters. It supports Docker and it runs on CoreOS.

In order to use ECS on CoreOS, you’ll need to add the “amazon-ecs-agent.service” unit to your existing cloud-config (or just use the cloud-config below in its entirety).
Be sure to replace “your_cluster_name” with an appropriate value or leave it blank to use the default cluster.

The service listed below pulls the latest official Amazon ECS agent container from the Docker hub when it starts.
If you ever need to update the agent, it’s as simple as restarting amazon-ecs-agent.service.

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
       
       [Service]
       Environment=ECS_CLUSTER=your_cluster_name
       ExecStartPre=-/usr/bin/docker kill ecs-agent
       ExecStartPre=-/usr/bin/docker rm ecs-agent
       ExecStartPre=/usr/bin/docker pull amazon/amazon-ecs-agent
       ExecStart=/usr/bin/docker run --name ecs-agent --env=ECS_CLUSTER=${ECS_CLUSTER} --publish=51678:51678 --volume=/var/run/docker.sock:/var/run/docker.sock --volume=/etc/ecs:/etc/ecs amazon/amazon-ecs-agent
       ExecStop=/usr/bin/docker stop ecs-agent
```
