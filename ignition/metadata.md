# Metadata

In many cases, it is desirable to inject dynamic data into services written by Ignition. Because Ignition itself is static and cannot inject dynamic data into configs, this must be done as the system starts. Container Linux ships with a small utility, `coreos-metadata`, which fetches information specific to the environment in which Container Linux is running. While this utility works only on officially supported platforms, it is possible to use the same paradigm to write a custom utility.

Each of these examples is written in version 2.0.0 of the config. Ensure that any configuration matches the version that Ignition expects.

## etcd2 with coreos-metadata

This config will write a systemd drop-in (shown below) for the etcd2.service. The drop-in modifies the ExecStart option, adding a few flags to etcd2's invocation. These flags use variables defined by coreos-metadata.service to change the interfaces on which etcd2 listens. coreos-metadata is provided by Container Linux and will read the appropriate metadata for the cloud environment (AWS in this example) and write the results to `/run/metadata/coreos`. For more information on the supported platforms and environment variables, refer to the [coreos-metadata documentation][metadata-docs].

```json ignition-config
{
  "ignition": { "version": "2.0.0" },
  "systemd": {
    "units": [{
      "name": "etcd2.service",
      "enable": true,
      "dropins": [{
        "name": "metadata.conf",
        "contents": "[Unit]\nRequires=coreos-metadata.service\nAfter=coreos-metadata.service\n\n[Service]\nEnvironmentFile=/run/metadata/coreos\nExecStart=\nExecStart=/usr/bin/etcd2 --advertise-client-urls=http://${COREOS_EC2_IPV4_PUBLIC}:2379 --initial-advertise-peer-urls=http://${COREOS_EC2_IPV4_LOCAL}:2380 --listen-client-urls=http://0.0.0.0:2379 --listen-peer-urls=http://${COREOS_EC2_IPV4_LOCAL}:2380 --initial-cluster=%m=http://${COREOS_EC2_IPV4_LOCAL}:2380"
      }]
    }]
  }
}
```

### metadata.conf

```ini
[Unit]
Requires=coreos-metadata.service
After=coreos-metadata.service

[Service]
EnvironmentFile=/run/metadata/coreos
ExecStart=
ExecStart=/usr/bin/etcd2 \
  --advertise-client-urls=http://${COREOS_EC2_IPV4_PUBLIC}:2379 \
  --initial-advertise-peer-urls=http://${COREOS_EC2_IPV4_LOCAL}:2380 \
  --listen-client-urls=http://0.0.0.0:2379 \
  --listen-peer-urls=http://${COREOS_EC2_IPV4_LOCAL}:2380 \
  --initial-cluster=%m=http://${COREOS_EC2_IPV4_LOCAL}:2380
```

## Custom metadata agent

When Container Linux is used outside of a supported cloud environment (for example, in a PXE booted, bare metal installation), coreos-metadata won't work. However, it is possible to write a custom metadata service.

This config will write a single service unit with the contents of a metadata agent service (shown below). This unit will not start on its own, because it is not enabled and is not a dependency of any other units. This metadata agent will fetch instance metadata from EC2 and save it to an ephemeral file.

```json ignition-config
{
  "ignition": { "version": "2.0.0" },
  "systemd": {
    "units": [{
      "name": "metadata.service",
      "contents": "[Unit]\nDescription=EC2 metadata agent\n\n[Service]\nType=oneshot\nEnvironment=OUTPUT=/run/metadata/ec2\nExecStart=/usr/bin/mkdir --parent /run/metadata\nExecStart=/usr/bin/bash -c 'echo \"CUSTOM_EC2_IPV4_PUBLIC=$(curl --url http://169.254.169.254/2009-04-04/meta-data/public-ipv4 --retry 10)\\nCUSTOM_EC2_IPV4_LOCAL=$(curl --url http://169.254.169.254/2009-04-04/meta-data/local-ipv4 --retry 10)\" > ${OUTPUT}'\n"
    }]
  }
}
```

### metadata.service

```ini
[Unit]
Description=EC2 metadata agent

[Service]
Type=oneshot
Environment=OUTPUT=/run/metadata/ec2
ExecStart=/usr/bin/mkdir --parent /run/metadata
ExecStart=/usr/bin/bash -c 'echo "CUSTOM_EC2_IPV4_PUBLIC=$(curl\
  --url http://169.254.169.254/2009-04-04/meta-data/public-ipv4\
  --retry 10)\nCUSTOM_EC2_IPV4_LOCAL=$(curl\
  --url http://169.254.169.254/2009-04-04/meta-data/local-ipv4\
  --retry 10)" > ${OUTPUT}'
```


[metadata-docs]: https://github.com/coreos/coreos-metadata/blob/master/docs/container-linux-legacy.md
