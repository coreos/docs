# Customizing the SSH daemon

CoreOS defaults to running an OpenSSH daemon using `systemd` socket activation -- when a client connects to the port configured for SSH, `sshd` is started on the fly for that client using a `systemd` unit derived automatically from a template. In some cases you may want to customize this daemon's authentication methods or other configuration. This guide will show you how to do that at build time using `cloud-config`, and after building by modifying the `systemd` unit file.

As a practical example, when a client fails to connect by not completing the TCP connection (e.g. because the "client" is actually a TCP port scanner), the MOTD may report failures of `systemd` units (which will be named by the source IP that failed to connect) next time you log in to the CoreOS host. These failures are not themselves harmful, but it is a good general practice to change how SSH listens, either by changing the IP address `sshd` listens to from the default setting (which listens on all configured interfaces), changing the default port, or both.

## Customizing sshd with cloud-config

In this example we will disable logins for the `root` user, only allow login for the `core` user and disable password based authentication. For more details on what sections can be added to `/etc/ssh/sshd_config` see the [OpenSSH manual][openssh-manual].

[openssh-manual]: http://www.openssh.com/cgi-bin/man.cgi?query=sshd_config

```yaml
#cloud-config

write_files:
  - path: /etc/ssh/sshd_config
    permissions: 0600
    owner: root:root
    content: |
      # Use most defaults for sshd configuration.
      UsePrivilegeSeparation sandbox
      Subsystem sftp internal-sftp

      PermitRootLogin no
      AllowUsers core
      PasswordAuthentication no
      ChallengeResponseAuthentication no
```

### Changing the sshd port

CoreOS ships with socket-activated SSH by default. The configuration for this can be found at `/usr/lib/systemd/system/sshd.socket`. We're going to override some of the default settings for this in the cloud-config provided at boot:

```yaml
#cloud-config

coreos:
  units:
  - name: sshd.socket
    command: restart
    runtime: true
    content: |
      [Socket]
      ListenStream=2222
      FreeBind=true
      Accept=yes
```

`sshd` will now listen only on port 2222 on all interfaces when the system is built.

### Further reading

Read the [full cloud-config]({{site.baseurl}}/docs/cluster-management/setup/cloudinit-cloud-config/) guide to install users and more.

## Customizing sshd after build

If you have CoreOS hosts that need configuration changes made after build, log into the CoreOS host as the core user, then:

```
$ sudo cp /usr/lib/systemd/system/sshd.socket /etc/systemd/system/sshd.socket
```

This gives you a copy of the sshd.socket unit that will override the one supplied by CoreOS -- when you make changes to it and `systemd` re-reads its configuration, those changes will be implemented.

### Changing the sshd port

To change how sshd listens, change or add the relevant lines in the `[Socket]` section of `/etc/systemd/system/sshd.socket` (leaving options not specified here intact).

To change just the listened-to port (in this example, port 2222):

```
[Socket]
ListenStream=2222
```

To change the listened-to IP address (in this example, 10.20.30.40):

```
[Socket]
ListenStream=10.20.30.40:22
FreeBind=true
```

You can specify both an IP and an alternate port in a single ListenStream line; additionally, IPv6 address bindings would be specified as, for example, `[2001:db8::7]:22`  Note two things: first, while a specific IP address is optional, you must always specify the port, even if it is the default SSH port. Second, the `FreeBind` option is used allow the socket to be bound on addresses that are not actually configured on an interface yet, to avoid issues caused by delays in IP configuration at boot. (This is not needed if you are not specifying an address.)

Multiple ListenStream lines can be specified, in which case `sshd` will listen on all the specified sockets:

```
[Socket]
ListenStream=2222
ListenStream=10.20.30.40:2223
FreeBind=true
```

`sshd` will now listen to port 2222 on all configured addresses, and port 2223 on 10.20.30.40.

Taking the last example, the complete contents of `/etc/systemd/system/sshd.socket` would now be:

```
[Unit]
Description=OpenSSH Server Socket
Conflicts=sshd.service

[Socket]
ListenStream=2222
ListenStream=10.20.30.40:2223
FreeBind=true
Accept=yes

[Install]
WantedBy=sockets.target
```

### Activating changes

After the edited file is written to disk, you can activate it without rebooting with:

```
$ sudo systemctl daemon-reload
```

We now see that systemd is listening on the new sockets:

```
$ systemctl status sshd.socket
● sshd.socket - OpenSSH Server Socket
   Loaded: loaded (/etc/systemd/system/sshd.socket; disabled; vendor preset: disabled)
   Active: active (listening) since Wed 2015-10-14 21:04:31 UTC; 2min 45s ago
   Listen: [::]:2222 (Stream)
           10.20.30.40:2223 (Stream)
 Accepted: 1; Connected: 0
...
```

And if we attempt to connect to port 22 on our public IP, the connection is rejected, but port 2222 works:

```
$ ssh core@[public IP]
ssh: connect to host [public IP] port 22: Connection refused
$ ssh -p 2222 core@[public IP]
Enter passphrase for key '/home/user/.ssh/id_rsa':
```

### Further reading on systemd units

For more information about configuring CoreOS hosts with `systemd`, see [Getting Started with systemd]({{site.baseurl}}/docs/launching-containers/launching/getting-started-with-systemd/).
