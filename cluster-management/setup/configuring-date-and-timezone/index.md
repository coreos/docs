---
layout: docs
title: Configuring Date & Timezone (NTP)
category: cluster_management
sub_category: setting_up
fork_url: https://github.com/coreos/docs/blob/master/cluster-management/setup/configuring-date-and-timezone/index.md
weight: 7
---

# Configuring Date and Timezone

NTP is used to to keep clocks in sync across machines in a CoreOS cluster.
CoreOS [681.0.0][681.0.0] uses [systemd-timesyncd][systemd-timesyncd] as the
default NTP client, prior to that [ntpd][ntp.org] was used. Depending on the
your version of CoreOS one of the two services will automatically start. To
check which service is running, run the follow command:

```
sudo systemctl status systemd-timesyncd ntpd
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

[681.0.0]: https://coreos.com/releases/#681.0.0
[ntp.org]: http://ntp.org/
[systemd-timesyncd]: http://www.freedesktop.org/software/systemd/man/systemd-timesyncd.service.html

## Switching between systemd-timesyncd and ntpd

If you are on CoreOS 681.0.0 or later you can switch back to the classic ntpd
with the following commands or cloud config:

```
sudo systemctl stop systemd-timesyncd
sudo systemctl mask systemd-timesyncd
sudo systemctl enable ntpd
sudo systemctl start ntpd
```

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

It important to mask the service you do not want to start. The
`systemctl disable` command will not override the system default to start.

## Changing NTP time servers

When using systemd-timesyncd NTP servers can be provided via DHCP, individual
[network][systemd.network] configs, [timesyncd.conf][timesyncd.conf], or the
built in default `*.coreos.pool.ntp.org` pool. For example, to disable the
default behavior of using NTP servers from DHCP write the following to
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

[systemd.network]: http://www.freedesktop.org/software/systemd/man/systemd.network.html
[timesyncd.conf]: http://www.freedesktop.org/software/systemd/man/timesyncd.conf.html

The ntpd service can be configured via the /etc/ntp.conf configuration file. It
does not use DHCP or other configuration sources. If you would like to use a
different set of NTP servers edit replace the `/etc/ntp.conf` symlink with
something like the following:

```
server 0.pool.example.com
server 1.pool.example.com

restrict default nomodify nopeer noquery limited kod
restrict 127.0.0.1
restrict [::1]
```

## Viewing the date and timezone settings with timedatectl

The timedatectl command can be use to view and change timezone settings as well as report the current time.

```
timedatectl status
      Local time: Tue 2014-08-26 19:29:12 UTC
  Universal time: Tue 2014-08-26 19:29:12 UTC
        RTC time: Tue 2014-08-26 19:29:12
       Time zone: UTC (UTC, +0000)
     NTP enabled: no
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
```

## Changing the system timezone

Start by listing the available time zones:

```
timedatectl list-timezones
Africa/Abidjan
Africa/Accra
Africa/Addis_Ababa
…
```

Pick a timezone from the list and set it:

```
sudo timedatectl set-timezone America/New_York
```

Check the timezone status to view the changes:

```
timedatectl
      Local time: Tue 2014-08-26 15:44:07 EDT
  Universal time: Tue 2014-08-26 19:44:07 UTC
        RTC time: Tue 2014-08-26 19:44:07
       Time zone: America/New_York (EDT, -0400)
     NTP enabled: no
NTP synchronized: yes
 RTC in local TZ: no
      DST active: yes
 Last DST change: DST began at
                  Sun 2014-03-09 01:59:59 EST
                  Sun 2014-03-09 03:00:00 EDT
 Next DST change: DST ends (the clock jumps one hour backwards) at
                  Sun 2014-11-02 01:59:59 EDT
                  Sun 2014-11-02 01:00:00 EST
```

## CoreOS Recommendations

### What time should I use?

To avoid time zone confusion and the complexities of adjusting clocks for
daylight saving time it’s recommended that all machines in a CoreOS cluster use
Coordinated Universal Time (UTC). This is the default.

```
sudo timedatectl set-timezone UTC
```

### Which NTP servers should I sync against?

Unless you have a highly reliable and precise time server pool you should stick to the default NTP servers from the ntp.org server pool.

```
server 0.coreos.pool.ntp.org
server 1.coreos.pool.ntp.org
server 2.coreos.pool.ntp.org
server 3.coreos.pool.ntp.org
```

## Automating with cloud-config

The following cloud-config snippet can be used setup and configure NTP and timezone settings:

```yaml
#cloud-config

coreos:
  units:
    - name: settimezone.service
      command: start
      content: |
        [Unit]
        Description=Set the timezone

        [Service]
        ExecStart=/usr/bin/timedatectl set-timezone America/New_York
        RemainAfterExit=yes
        Type=oneshot
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
  - path: /etc/systemd/timesyncd.conf
    content: |
      [Time]
      NTP=0.pool.example.com 1.pool.example.com
```
