# Metadata

In many cases, it is desirable to inject dynamic data into services writen by Ignition. Because Ignition itself is static and cannot inject dynamic data into configs, this has to be done as the system starts. CoreOS ships with a small utility, `coreos-metadata`, which fetches information specific to the environment in which CoreOS is running. While this utility only works on officially supported platforms, it is possible to use the same paradigm to write a custom utility.

Each of these examples is written in version 2.0.0 of the config. Ensure that any configuration matches the version that Ignition expects.


## etcd2 with coreos-metadata

This config will write a systemd drop-in (shown below) for the etcd2.service. The drop-in modifies the ExecStart option, adding a few flags to etcd2's invocation. These flags use variables defined by coreos-metadata.service to change the interfaces on which etcd2 listens. coreos-metadata is provided by CoreOS and will read the appropriate metadata for the cloud environment (AWS in this example) and write the results to `/run/metadata/coreos`. For more information on the supported platforms and environment variables, refer to the [coreos-metadata README](https://github.com/coreos/coreos-metadata/blob/master/README.md)

```json
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

```
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

In the event that CoreOS is being used outside of a supported cloud environment (e.g., a PXE booted, bare-metal installation), coreos-metadata won't work. However, it is possible to write a custom metadata service.

This config will write a single service unit with the contents of a metadata agent service (shown below). This unit will not start on its own, because it is not enabled and is not a dependency of any other units. This metadata agent will fetch instance metadata from EC2 and save it to an ephemeral file.

```json
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

```
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
