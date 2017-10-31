# Notes for distributors

## Importing images

Images of Container Linux alpha releases are hosted at `https://alpha.release.core-os.net/amd64-usr/`. There are directories for releases by version as well as `current` with a copy of the latest version. Similarly, beta releases can be found at `https://beta.release.core-os.net/amd64-usr/` and stable releases at `https://stable.release.core-os.net/amd64-usr/`.

If you are importing images for use inside of your environment it is recommended that you import from the `current` directory. For example to grab the alpha OpenStack version of Container Linux you can import `https://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2`. There is a `version.txt` file in this directory which you can use to label the image with a version number.

It is recommended that you also verify files using the [CoreOS Image Signing Key][signing-key]. The GPG signature for each image is a detached `.sig` file that must be passed to `gpg --verify`. For example:

```sh
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2.sig
gpg --verify coreos_production_openstack_image.img.bz2.sig
```

[signing-key]: https://coreos.com/security/image-signing-key

## Image customization

There are two predominant ways that a Container Linux image can be easily customized for a specific operating environment: through Ignition, a first-boot provisioning tool that runs during a machine's boot process, and through [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md), an older tool that runs every time a machine boots.

### Ignition

[Ignition][ignition] is a tool that acquires a JSON config file when a machine first boots, and uses this config to perform tasks such as formatting disks, creating files, modifying and creating users, and adding systemd units. How Ignition acquires this config file varies per-platform, and it is highly recommended that providers ensure Ignition has [support for their platform][ign-platforms].

Use Ignition to handle platform specific configuration such as custom networking, running an agent on the machine, or injecting files onto disk.

Additionally, it is recommended that providers ensure that [coreos-metadata][coreos-metadata] and [ct][ct] have support for their platform. This will allow a nicer user experience, as coreos-metadata will be able to install users ssh keys and users will be able to reference dynamic data in their Container Linux Configs.

[ignition]: https://coreos.com/blog/introducing-ignition.html
[ign-platforms]: https://github.com/coreos/ignition/blob/master/doc/supported-platforms.md
[coreos-metadata]: https://github.com/coreos/coreos-metadata/
[ct]: https://github.com/coreos/container-linux-config-transpiler

### Cloud config

A Container Linux image can also be customized using [cloud-config](https://github.com/coreos/coreos-cloudinit/blob/master/Documentation/cloud-config.md). Users are recommended to instead use Container Linux Configs (that are converted into Ignition configs with [ct][ct]), for reasons [outlined in the blog post that introduced Ignition][ignition].

Providers should still ensure that their platform is supported in cloud-config however, as not all users have switched over to Container Linux Configs.

Container Linux will automatically parse and execute `/usr/share/oem/cloud-config.yml` if it exists.

## Handling end-user Ignition files

End-users should be able to provide an Ignition file to your platform while specifying their VM's parameters. This file should be made available to Container Linux at the time of boot (e.g. at known network address, injected directly onto disk). Examples of these data sources can be found in the [Ignition documentation][providers].

[providers]: https://github.com/coreos/ignition/blob/master/doc/supported-platforms.md
