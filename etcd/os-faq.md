# etcd on Container Linux FAQ

Are you planning on running etcd on CoreOS Container Linux? The following FAQ clarifies some common misconceptions.

## What is the current version of etcd?

[v3][etcd-latest-version].

## Where do I find etcd v3 in Container Linux?

Container Linux includes a systemd service, [etcd-member.service][etcd-member-service], which pulls and runs a desired version of etcd (defaults to v3) in a rkt container. This functions as if the etcd binary was being run, but does not require the binary to be installed on your Container Linux node.

Newer versions of the etcd binary (v3) are not planned to be included in the OS.

## Why is etcd v2 still in the os?

The etcd binary will be included in the OS until June, 2018.

The preferred way to run etcd in Container Linux is to use the etcd-member service mentioned above in the first question.

## When will v3 be included in the OS image?

Never.

Etcd v3 is shipped as a container and used via the etcd-member systemd service (see the first question for more information).

# Can I curl the v3 api?

No.

The etcd v3 API uses gRPC, which can not be interacted with via curl. Use etcdctl to interact with etcd clusters as this can be used to interact with a given cluster's v3 *and* v2 APIs.

# How do I provision machines with etcd and config?

The preferred way to provision *any* Container Linux machine is to write a [Container Linux Config][clconfig]. This config allows easy configuration of networking, storage, users, docker, flannel, etcd, systemd, update channel, image verification, and locksmith.

As part of the installation process, this YAML file is converted into an Ignition config. On first system boot the Container Linux node is configured into the desired state specified in the Container Linux Config. See an example of how to use this in the [Getting started with etcd][getting-started] guide.

# Can etcd be configured with cloud-config?

The preferred way to configure a Container Linux machine is with Container Linux configs and Ignition. The Container Linux Config Transpiler docs include [an etcd configuration example][clct-etcd-example].

Cloud-Config is still a supported configuration method, however it does not have any etcd v3 specific support.

[etcd-latest-version]: https://github.com/coreos/etcd/releases
[etcd-member-service]: https://github.com/coreos/coreos-overlay/blob/master/app-admin/etcd-wrapper/files/etcd-member.service
[getting-started]: https://coreos.com/etcd/docs/latest/getting-started-with-etcd.html
[clconfig]: https://coreos.com/os/docs/latest/configuration.html
[clct-etcd-example]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/examples.md#etcd
