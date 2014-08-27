---
layout: docs
title: Configuring Date & Timezone (NTP)
category: cluster_management
sub_category: setting_up
weight: 7
---

# Configuring Date and Timezone

NTP is used to to keep clocks in sync across machines in a CoreOS cluster. The ntpd service is responsible for keeping each machines local clock in sync with a configured set of time servers. The services will automatically start by default. To check if the ntpd service is running, run the follow command:

```
systemctl status ntpd
ntpd.service - Network Time Service
   Loaded: loaded (/usr/lib64/systemd/system/ntpd.service; enabled)
   Active: active (running) since Tue 2014-08-26 15:10:23 UTC; 4h 23min ago
 Main PID: 483 (ntpd)
   CGroup: /system.slice/ntpd.service
           └─483 /usr/sbin/ntpd -g -n -u ntp:ntp -f /var/lib/ntp/ntp.drift
```

## Changing NTP time servers

The ntpd service can be configured via the /etc/ntp.conf configuration file. By default systems will sync time with NTP servers from ntp.org. If you would like to use a different set of NTP servers edit /etc/ntp.conf:

```
# Common pool
server 0.pool.example.com
server 1.pool.example.com
...
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
     NTP enabled: yes
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

To avoid time zone confusion and the complexities of adjusting clocks for daylight saving time it’s recommended that all machines in a CoreOS cluster use Coordinated Universal Time (UTC).

```
sudo timedatectl set-timezone UTC
```

### Which NTP servers should I sync against?

Unless you have a highly reliable and precise time server pool you should stick to the default NTP servers from the ntp.org server pool.

```
server 0.pool.ntp.org
server 1.pool.ntp.org
server 2.pool.ntp.org
server 3.pool.ntp.org
```

## Automating with cloud-config

The following cloud-config snippet can be used setup and configure NTP and timezone settings: 

```
#cloud-config

coreos:
  units:
    - name: settimezone.service
      command: start
      content: |
        [Unit]
        Description=Set the timezone

        [Service]
        ExecStart=/usr/bin/timedatectl set-timezone UTC
        RemainAfterExit=yes
        Type=oneshot
write_files:
  - path: /etc/ntp.conf
    content: |
      # Common pool
      server 0.pool.ntp.org
      server 1.pool.ntp.org

      # - Allow only time queries, at a limited rate.
      # - Allow all local queries (IPv4, IPv6)
      restrict default nomodify nopeer noquery limited kod
      restrict 127.0.0.1
      restrict [::1]
```
