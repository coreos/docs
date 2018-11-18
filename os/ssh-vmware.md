# Adding SSH keys for VMWare

Most installations of Container Linux on VMWare require an SSH key to access the machine. Use a [Container Linux Config][cl-config] with a valid SSH key and the [Config Transpiler][config-transpiler] to create the ignition config. Then pass that ignition config to the VMWare image’s VMX file to enable SSH access to the machine.

Modify the VMX file to pass an [Ignition Config][ignition-config] containing at least one valid SSH key.

First, follow the instructions to Boot with VMware Workstation 12 or VMware Fusion to create a VM. (Do not start / power on the the VM. These instructions will work only on the first boot.)

Next, create and apply the SSH key:

1. [Download Config Transpiler][download-ct].

2. Follow the instructions to [add an SSH public key][add-ssh] to the Container Linux Config (for example `id_rsa.pub`).

```
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h..."
```

3. Use Config Transpiler to convert the Container Linux Config YAML to Ignition Config, then base64 encode the Ignition config.

```
$ ./ct --in-file config.yaml | base64
```

Remove any newline characters from the encoded output.

4. Open the VM’s VMX file in your favorite text editor, and add the base64 encoded Ignition Config to the VMWare image’s VMX file under Guestinfo as outlined in [Defining the Ignition config in Guestinfo][define-guestinfo].

```
guestinfo.coreos.config.data = "<<Output of the base64 encoded ignition file>>>"
guestinfo.coreos.config.data.encoding = "base64"
```

5. Save the VMX file and boot the VM for the first time.

Once booted, use `$ ssh core@<<ip address>>` to SSH into the machine. If you haven’t added the SSH key to the SSH agent, specify the key using the `-i` flag:

`$ ssh -i <<path to ssh public key>> core@<<ip address>>`


[add-ssh]: https://coreos.com/os/docs/latest/migrating-to-clcs.html#ssh_authorized_keys
[config-transpiler]: https://coreos.com/os/docs/latest/overview-of-ct.html
[define-guestinfo]: https://coreos.com/os/docs/latest/booting-on-vmware.html#defining-the-ignition-config-in-guestinfo
[download-ct]: https://github.com/coreos/container-linux-config-transpiler/releases/
[ignition-config]: https://coreos.com/os/docs/latest/provisioning.html#ignition-config
[cl-config]: https://coreos.com/os/docs/latest/provisioning.html
