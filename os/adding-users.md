# Adding users

You can create user accounts on a CoreOS machine manually with `useradd` or via cloud-config when the machine is created.

## Add users via cloud-config

Managing users via cloud-config is preferred because it allows you to use the same configuration across many servers and the cloud-config file can be stored in a repo and versioned. In your cloud-config, you can specify many [different parameters]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config/#users) for each user. Here's an example:

```yaml
#cloud-config

users:
  - name: elroy
    passwd: $6$5s2u6/jR$un0AvWnqilcgaNB3Mkxd5yYv6mTlWfOoCYHZmfi3LDKVltj.E8XNKEcwWm...
    groups:
      - sudo
      - docker
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
```

Check out the entire [Customize with Cloud-Config]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config/) guide for the full details.

## Add Users via Ignition

Managing users via Ignition is preferred because it allows you to use the same configuration across many servers and the Ignition config can be stored in a repo and versioned. In your Ignition config, you can specify many [different parameters](https://github.com/coreos/ignition/blob/master/doc/configuration.md) for each user. Here's an example:

```json
{
  "ignition": { "version": "2.0.0" },
  "passwd": {
    "users": [{
      "name": "elroy",
      "passwordHash": "$6$5s2u6/jR$un0AvWnqilcgaNB3Mkxd5yYv6mTlWfOoCYHZmfi3LDKVltj.E8XNKEcwWm...",
      "groups": [
        "sudo",
        "docker"
      ],
      "sshAuthorizedKeys": [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq......." ],
      "create": {}
    }]
  }
}
```

## Add user manually

If you'd like to add a user manually, SSH to the machine and use the `useradd` tool. To create the user `user`, run:

```sh
sudo useradd -p "*" -U -m user1 -G sudo
```

The `"*"` creates a user that cannot login with a password but can log in via SSH key. `-U` creates a group for the user, `-G` adds the user to the existing `sudo` group and `-m` creates a home directory. If you'd like to add a password for the user, run:

```sh
$ sudo passwd user1
New password:
Re-enter new password:
passwd: password changed.
```

To assign an SSH key, run:

```sh
update-ssh-keys -u user1 user1.pem
```

## Further reading

Read the [full cloud-config]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config/) guide to install users and more.
