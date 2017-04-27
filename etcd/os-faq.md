# etcd on Container Linux FAQ

Questions often asked when using etcd v3 on CoreOS Container Linux

## What is the current version of etcd?

The version 3 series is the latest edition of the etcd binary and API. The [current release is the latest release in the version 3 series][etcd-latest-version].

## Where do I find etcd v3 in Container Linux?

Container Linux includes a systemd service, [etcd-member.service][etcd-member-service], that knows how to fetch and run etcd v3 in a Linux container. No etcd v3-series binary is directly included in the Container Linux filesystem.

## Why is etcd v2 still part of the Container Linux filesystem?

For reasons of compatibility, previous, deprecated versions of etcd, named `etcd` and `etcd2`, are included in the Container Linux filesystem until they complete their [sunset schedules][etcd3-blog] and are finally removed.

The etcd (v0) binary will be removed from Container Linux in May, 2017.

The etcd2 binary will be included in the OS until June, 2018.

The recommended way to run etcd on Container Linux is to use the etcd-member service.

## When will v3 be included in the OS image?

Version 3-series etcd binaries are packaged in a Linux container and instantiated by the `etcd-member.service` systemd unit.

# Can I curl the v3 api?

No. The etcd v3 API uses gRPC rather than plain text HTTP. Use `etcdctl` to interact with the etcd v3 API.

# How do I provision etcd cluster members?

The preferred way to provision *any* Container Linux machine is with a [Container Linux Config][clconfig]. See an example Container Linux Config for etcd in the [getting started with etcd guide][getting-started].

# Can etcd be configured with cloud-config?

The preferred way to configure a Container Linux machine is with Container Linux configs and Ignition. The Container Linux Config Transpiler docs include [an etcd configuration example][clct-etcd-example].


[etcd3-blog]: https://coreos.com/blog/toward-etcd-v3-in-container-linux.html
[etcd-latest-version]: https://github.com/coreos/etcd/releases
[etcd-member-service]: https://github.com/coreos/coreos-overlay/blob/master/app-admin/etcd-wrapper/files/etcd-member.service
[getting-started]: https://coreos.com/etcd/docs/latest/getting-started-with-etcd.html
[clconfig]: https://coreos.com/os/docs/latest/configuration.html
[clct-etcd-example]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/examples.md#etcd
