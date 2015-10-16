# Centralized Logging

**NOTE**: `systemd-journal-remote` works only on CoreOS 845.0.0 or greater.

`systmed-journald` components can be configured to store logs in a central repository. These components can act both as a client, forwarding logs to a storage host, and as a server, collecting logs from remote clients and writing them to local storage.

* [systemd-journal-remote][journal-remote] - collects logs from remote hosts (server)
* [systemd-journal-upload][journal-upload] - forwards logs into centralized storage (client)

systemd-journal-remote supports two types of sources:

* active - requests and pulls the data
* passive - waits for a connection and then receives events pushed by the client side

This documentation describes the *passive* method, which can be compared to the centralized logging provided by [`rsyslogd(8)`](http://linux.die.net/man/8/rsyslogd) or [`syslog-ng`](http://linux.die.net/man/8/syslog-ng). This introductory example will not cover encryption of the log stream.

## Configuration

### Server Configuration

```yaml
#cloud-config

coreos:
  units:
    - name: systemd-journal-remote.service
      drop-ins:
        - name: 10-use-http.conf
          content: |
          [Service]
          ExecStart=
          ExecStart=/usr/lib/systemd/systemd-journal-remote --listen-http=-3 --output=/var/log/journal/remote
      command: start
```

### Client Configuration

Set `URL=http://journal-remote:19532` where `journal-remote` is your log aggregator server name.

```yaml
#cloud-config

write_files:
  - path: "/etc/systemd/journal-upload.conf"
    permissions: "0644"
    owner: "root"
    content: |
      [Upload]
      URL=http://journal-remote:19532
  - path: "/etc/tmpfiles.d/systemd-upload.conf"
    permissions: "0644"
    owner: "root"
    content: |
      d /var/lib/systemd/journal-upload 0755 systemd-journal-upload systemd-journal-upload
coreos:
  units:
    - name: systemd-journal-upload.service
      command: start
```

## Read Remote Logs

Here you can find an examples on how to read logs transmitted from the remote client on log aggregator host.

Read all logs which were transmitted from remote clients:

```sh
journalctl -D /var/log/journal/remote -f
```

Read application logs:

```sh
journalctl -D /var/log/journal/remote -f -t %application_name%
```

Read logs by application PID:

```sh
journalctl _PID=27543 -D /var/log/journal/remote -f
```

Read logs by application path:

```sh
journalctl _EXE=/usr/bin/coreos-cloudinit -D /var/log/journal/remote -f
```

Read logs by hostname:

```sh
journalctl _HOSTNAME=core-02 -D /var/log/journal/remote -f
```

[journal-remote]: http://www.freedesktop.org/software/systemd/man/systemd-journal-remote.html
[journal-upload]: http://www.freedesktop.org/software/systemd/man/systemd-journal-upload.html

#### More Information
<a class="btn btn-default" href="getting-started-with-systemd.md">Getting Started with systemd</a>
<a class="btn btn-default" href="reading-the-system-log.md">Reading the System Log</a>
