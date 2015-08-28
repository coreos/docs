# Configuring Date and Time Zone

By default, CoreOS machines keep time in the Coordinated Universal Time (UTC)
zone and synchronize their clocks with the Network Time Protocol (NTP).
This page contains information about customizing those defaults, explains
the change in NTP client daemons in recent CoreOS versions, and offers advice
on best practices for timekeeping in CoreOS clusters.

## Viewing and Changing Time and Date

The [`timedatectl(1)`][timedatectl] command displays and sets the date, time,
and time zone.

```
$ timedatectl status
      Local time: Wed 2015-08-26 19:29:12 UTC
  Universal time: Wed 2015-08-26 19:29:12 UTC
        RTC time: Wed 2015-08-26 19:29:12
       Time zone: UTC (UTC, +0000)
 Network time on: no
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
```

### Recommended: UTC Time
To avoid time zone confusion and the complexities of adjusting clocks for
daylight saving time (or not) in accordance with regional custom, we recommend
that all machines in CoreOS clusters use UTC. This is the default time zone. To
reset a machine to this default:

```
$ sudo timedatectl set-timezone UTC
```

### Changing the Time Zone

If your site or application requires a different system time zone, start by
listing the available options:

```
$ timedatectl list-timezones
Africa/Abidjan
Africa/Accra
Africa/Addis_Ababa
…
```

Pick a time zone from the list and set it:

```
$ sudo timedatectl set-timezone America/New_York
```

Check the changes:

```
$ timedatectl
      Local time: Wed 2015-08-26 15:44:07 EDT
  Universal time: Wed 2015-08-26 19:44:07 UTC
        RTC time: Wed 2015-08-26 19:44:07
       Time zone: America/New_York (EDT, -0400)
 Network time on: no
NTP synchronized: yes
 RTC in local TZ: no
      DST active: yes
 Last DST change: DST began at
                  Sun 2015-03-08 01:59:59 EST
                  Sun 2015-03-08 03:00:00 EDT
 Next DST change: DST ends (the clock jumps one hour backwards) at
                  Sun 2015-11-01 01:59:59 EDT
                  Sun 2015-11-01 01:00:00 EST
```

Time zone may instead be set in cloud-config, with something like the following
excerpt:

```yaml
#cloud-config
coreos:
  units:
    - name: settimezone.service
      command: start
      content: |
        [Unit]
        Description=Set the time zone

        [Service]
        ExecStart=/usr/bin/timedatectl set-timezone America/New_York
        RemainAfterExit=yes
        Type=oneshot
```


## Time Synchronization

CoreOS clusters use NTP to synchronize the clocks of member nodes, and all
machines start an NTP client at boot. CoreOS versions later than
[681.0.0][681.0.0] use [`systemd-timesyncd(8)`][systemd-timesyncd] as the
default NTP client. Earlier versions used [`ntpd(8)`][ntp.org]. Use `systemctl`
to check which service is running:

```
$ systemctl status systemd-timesyncd ntpd
● systemd-timesyncd.service - Network Time Synchronization
   Loaded: loaded (/usr/lib64/systemd/system/systemd-timesyncd.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2015-05-14 05:43:20 UTC; 5 days ago
     Docs: man:systemd-timesyncd.service(8)
 Main PID: 480 (systemd-timesyn)
   Status: "Using Time Server 169.254.169.254:123 (169.254.169.254)."
   Memory: 448.0K
   CGroup: /system.slice/systemd-timesyncd.service
           └─480 /usr/lib/systemd/systemd-timesyncd

● ntpd.service - Network Time Service
   Loaded: loaded (/usr/lib64/systemd/system/ntpd.service; disabled; vendor preset: disabled)
   Active: inactive (dead)
```

### Recommended NTP Sources

Unless you have a highly reliable and precise time server pool, use your cloud
provider's NTP source, or, on bare metal, the default CoreOS NTP servers:

```
0.coreos.pool.ntp.org
1.coreos.pool.ntp.org
2.coreos.pool.ntp.org
3.coreos.pool.ntp.org
```

### Changing NTP Time Sources

`Systemd-timesyncd` can discover NTP servers from DHCP, individual
[network][systemd.network] configs, the file [`timesyncd.conf`][timesyncd.conf],
or the default `*.coreos.pool.ntp.org` pool.

The default behavior uses NTP servers provided by DHCP. To disable this, write
a configuration listing your preferred NTP servers into the file
`/etc/systemd/network/50-dhcp-no-ntp.conf`:

```ini
[Network]
DHCP=v4
NTP=0.pool.example.com 1.pool.example.com

[DHCP]
UseMTU=true
UseDomains=true
UseNTP=false
```

Then restart the network daemon:

```
$ sudo systemctl restart systemd-networkd
```

NTP time sources can be set in `timesyncd.conf` with a cloud-config snippet like:

```yaml
#cloud-config
coreos:
  write_files:
  - path: /etc/systemd/timesyncd.conf
    content: |
      [Time]
      NTP=0.pool.example.com 1.pool.example.com
```


## Switching from `timesyncd` to `ntpd`

On CoreOS 681.0.0 or later, you can switch from `systemd-timesyncd` back
to `ntpd` with the following commands:

```
$ sudo systemctl stop systemd-timesyncd
$ sudo systemctl mask systemd-timesyncd
$ sudo systemctl enable ntpd
$ sudo systemctl start ntpd
```

or with this cloud-config snippet:

```yaml
#cloud-config
coreos:
  units:
    - name: systemd-timesyncd.service
      command: stop
      mask: true
    - name: ntpd.service
      command: start
      enable: true
```

Because `timesyncd` and `ntpd` are mutually exclusive, it's important to `mask`
the `stop`ped service. `Systemctl disable` or `stop` alone will not prevent a
default service from starting again.

### Configuring `ntpd`

The `ntpd` service reads all configuration from the file `/etc/ntp.conf`. It
does not use DHCP or other configuration sources. To use a
different set of NTP servers, replace the `/etc/ntp.conf` symlink with
something like the following:

```
server 0.pool.example.com
server 1.pool.example.com

restrict default nomodify nopeer noquery limited kod
restrict 127.0.0.1
restrict [::1]
```

Then ask `ntpd` to reload its configuration:

```
$ sudo systemctl reload ntpd
```

Or, in cloud-config:

```yaml
#cloud-config
coreos:
  write_files:
  - path: /etc/ntp.conf
    content: |
      server 0.pool.example.com
      server 1.pool.example.com

      # - Allow only time queries, at a limited rate.
      # - Allow all local queries (IPv4, IPv6)
      restrict default nomodify nopeer noquery limited kod
      restrict 127.0.0.1
      restrict [::1]
```

[timedatectl]: http://www.freedesktop.org/software/systemd/man/timedatectl.html
[681.0.0]: https://coreos.com/releases/#681.0.0
[ntp.org]: http://ntp.org/
[systemd-timesyncd]: http://www.freedesktop.org/software/systemd/man/systemd-timesyncd.service.html
[systemd.network]: http://www.freedesktop.org/software/systemd/man/systemd.network.html
[timesyncd.conf]: http://www.freedesktop.org/software/systemd/man/timesyncd.conf.html
