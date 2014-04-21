---
layout: docs
title: Adding Users
category: cluster_management
sub_category: setting_up
weight: 7
---

# Adding Users

You can create user accounts on a CoreOS machine manually with `useradd` or via cloud-config when the machine is created.

## Add Users via Cloud-Config

Managing users via cloud-config is preferred because it allows you to use the same configuration across many servers and the cloud-config file can be stored in a repo and versioned. In your cloud-config, you can specify many [different parameters]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/#users) for each user. Here's an example:

```
#cloud-config

users:
  - name: elroy
    passwd: $6$5s2u6/jR$un0AvWnqilcgaNB3Mkxd5yYv6mTlWfOoCYHZmfi3LDKVltj.E8XNKEcwWm...
    groups:
      - sudo
      - docker
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h...
```

Check out the entire [Customize with Cloud-Config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/) guide for the full details.

## Add User Manually

If you'd like to add a user manually, SSH to the machine and use the `useradd` toll. To create the user `user`, run:

```
sudo useradd -p "*" -U -m user1 -G sudo
```

The `"*"` creates a user that cannot login with a password but can log in via SSH key. `-U` creates a group for the user, `-G` adds the user to the existing `sudo` group and `-m` creates a home directory. If you'd like to add a password for the user, run:

```
$ sudo passwd user1
New password: 
Re-enter new password: 
passwd: password changed.
```

To assign an SSH key, run:

```
update-ssh-keys -u user1 user1.pem
```

## Further Reading

Read the [full cloud-config]({{site.url}}/docs/cluster-management/setup/cloudinit-cloud-config/) guide to install users and more.