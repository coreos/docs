# Running CoreOS Container Linux with AWS EC2 Container Service

[Amazon EC2 Container Service (ECS)](http://aws.amazon.com/ecs/) is a container management service which provides a set of APIs for scheduling container workloads across EC2 clusters. It supports Container Linux with Docker containers.

Your Container Linux machines communicate with ECS via an agent. The agent interacts with Docker to start new containers and gather information about running containers.

## Set up a new cluster

When booting your [Container Linux Machines on EC2](booting-on-ec2.md), configure the ECS agent to be started via [Ignition][ignition-docs].

Be sure to change `ECS_CLUSTER` to the cluster name you've configured via the ECS CLI or leave it empty for the default. Here's a full config example:

```container-linux-config:ec2
systemd:
 units:
   - name: amazon-ecs-agent.service
     enable: true
     contents: |
       [Unit]
       Description=AWS ECS Agent
       Documentation=https://docs.aws.amazon.com/AmazonECS/latest/developerguide/
       Requires=docker.socket
       After=docker.socket

       [Service]
       Environment=ECS_CLUSTER=your_cluster_name
       Environment=ECS_LOGLEVEL=info
       Environment=ECS_VERSION=latest
       Restart=on-failure
       RestartSec=30
       RestartPreventExitStatus=5
       SyslogIdentifier=ecs-agent
       ExecStartPre=-/bin/mkdir -p /var/log/ecs /var/ecs-data /etc/ecs
       ExecStartPre=-/usr/bin/touch /etc/ecs/ecs.config
       ExecStartPre=-/usr/bin/docker kill ecs-agent
       ExecStartPre=-/usr/bin/docker rm ecs-agent
       ExecStartPre=/usr/bin/docker pull amazon/amazon-ecs-agent:${ECS_VERSION}
       ExecStart=/usr/bin/docker run \
           --name ecs-agent \
           --env-file=/etc/ecs/ecs.config \
           --volume=/var/run/docker.sock:/var/run/docker.sock \
           --volume=/var/log/ecs:/log \
           --volume=/var/ecs-data:/data \
           --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
           --volume=/run/docker/execdriver/native:/var/lib/docker/execdriver/native:ro \
           --publish=127.0.0.1:51678:51678 \
           --env=ECS_LOGFILE=/log/ecs-agent.log \
           --env=ECS_LOGLEVEL=${ECS_LOGLEVEL} \
           --env=ECS_DATADIR=/data \
           --env=ECS_CLUSTER=${ECS_CLUSTER} \
           amazon/amazon-ecs-agent:${ECS_VERSION}

       [Install]
       WantedBy=multi-user.target
```

The example above pulls the latest official Amazon ECS agent container from the Docker Hub when the machine starts. If you ever need to update the agent, it’s as simple as restarting the amazon-ecs-agent service or the Container Linux machine.

If you want to configure SSH keys in order to log in, mount disks or configure other options, see the [Container Linux Configs documentation][cl-configs].

[cl-configs]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/getting-started.md

## Connect ECS to an existing cluster

Connecting an existing cluster to ECS is simple with [fleet](../fleet/launching-containers-fleet.md) &mdash; the agent can be run as a global unit. The unit looks similar to the example above:

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
