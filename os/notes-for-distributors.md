# Notes for distributors

## Importing images

Images of Container Linux alpha releases are hosted at [`https://alpha.release.core-os.net/amd64-usr/`][alpha-bucket]. There are directories for releases by version as well as `current` with a copy of the latest version. Similarly, beta releases can be found at [`https://beta.release.core-os.net/amd64-usr/`][beta-bucket] and stable releases at [`https://stable.release.core-os.net/amd64-usr/`][stable-bucket].

Each directory has a `version.txt` file containing version information for the files in that directory. If you are importing images for use inside your environment it is recommended that you fetch `version.txt` from the `current` directory and use its contents to compute the path to the other artifacts. For example, to download the alpha OpenStack version of Container Linux:

1. Download `https://alpha.release.core-os.net/amd64-usr/current/version.txt`.
2. Parse `version.txt` to obtain the value of `COREOS_VERSION_ID`, for example `1576.1.0`.
3. Download `https://alpha.release.core-os.net/amd64-usr/1576.1.0/coreos_production_openstack_image.img.bz2`.

It is recommended that you also verify files using the [CoreOS Image Signing Key][signing-key]. The GPG signature for each image is a detached `.sig` file that must be passed to `gpg --verify`. For example:

```sh
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2.sig
gpg --verify coreos_production_openstack_image.img.bz2.sig
```

The signing key is rotated annually. We will announce upcoming rotations of the signing key on the [user mailing list][coreos-user].

[alpha-bucket]: https://alpha.release.core-os.net/amd64-usr/
[beta-bucket]: https://beta.release.core-os.net/amd64-usr/
[stable-bucket]: https://stable.release.core-os.net/amd64-usr/
[signing-key]: https://coreos.com/security/image-signing-key
[coreos-user]: https://groups.google.com/forum/#!forum/coreos-user

## Image customization

There are two predominant ways that a Container Linux image can be easily customized for a specific operating environment: through Ignition, a first-boot provisioning tool that runs during a machine's boot process, and through [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md), an older tool that runs every time a machine boots.

### Ignition

[Ignition][ignition] is a tool that acquires a JSON config file when a machine first boots, and uses this config to perform tasks such as formatting disks, creating files, modifying and creating users, and adding systemd units. How Ignition acquires this config file varies per-platform, and it is highly recommended that providers ensure Ignition has [support for their platform][ign-platforms].

Use Ignition to handle platform specific configuration such as custom networking, running an agent on the machine, or injecting files onto disk. To do this, place an Ignition config at `/usr/share/oem/base/base.ign` and it will be prepended to the user provided config. In addition, any config placed at `/usr/share/oem/base/default.ign` will be executed if a user config is not found. On platforms that support cloud-config, use this feature to run coreos-cloudinit when no Ignition config is provided.

Additionally, it is recommended that providers ensure that [coreos-metadata][coreos-metadata] and [ct][ct] have support for their platform. This will allow a nicer user experience, as coreos-metadata will be able to install users' ssh keys and users will be able to reference dynamic data in their Container Linux Configs.

[ignition]: https://coreos.com/blog/introducing-ignition.html
[ign-platforms]: https://github.com/coreos/ignition/blob/master/doc/supported-platforms.md
[coreos-metadata]: https://github.com/coreos/coreos-metadata/
[ct]: https://github.com/coreos/container-linux-config-transpiler

### Cloud config

A Container Linux image can also be customized using [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md). Users are recommended to instead use Container Linux Configs (that are converted into Ignition configs with [ct][ct]), for reasons [outlined in the blog post that introduced Ignition][ignition].

Providers that previously supported cloud-config should continue to do so, as not all users have switched over to Container Linux Configs. New platforms do not need to support cloud-config.

Container Linux will automatically parse and execute `/usr/share/oem/cloud-config.yml` if it exists.

## Handling end-user Ignition files

End-users should be able to provide an Ignition file to your platform while specifying their VM's parameters. This file should be made available to Container Linux at the time of boot (e.g. at known network address, injected directly onto disk). Examples of these data sources can be found in the [Ignition documentation][providers].

[providers]: https://github.com/coreos/ignition/blob/master/doc/supported-platforms.md
