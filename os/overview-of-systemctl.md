# Overview of systemctl

`systemctl` is your interface to systemd, the init system used in CoreOS. All processes on a single machine are started and managed by systemd, including your Docker containers. You can learn more in our [Getting Started with systemd](getting-started-with-systemd.md) guide. Let's explore a few helpful `systemctl` commands. You must run all of these commands locally on the CoreOS machine:

## Find the status of a container

The first step to troubleshooting with `systemctl` is to find the status of the item in question. If you have multiple `Exec` commands in your service file, you can see which one of them is failing and view the exit code. Here's a failing service that starts a private Docker registry in a container:

```sh
$ sudo systemctl status custom-registry.service

custom-registry.service - Custom Registry Service
   Loaded: loaded (/media/state/units/custom-registry.service; enabled-runtime)
   Active: failed (Result: exit-code) since Sun 2013-12-22 12:40:11 UTC; 35s ago
  Process: 10191 ExecStopPost=/usr/bin/etcdctl delete /registry (code=exited, status=0/SUCCESS)
  Process: 10172 ExecStartPost=/usr/bin/etcdctl set /registry index.domain.com:5000 (code=exited, status=0/SUCCESS)
  Process: 10171 ExecStart=/usr/bin/docker run -rm -p 5555:5000 54.202.26.87:5000/registry /bin/sh /root/boot.sh (code=exited, status=1/FAILURE)
 Main PID: 10171 (code=exited, status=1/FAILURE)
   CGroup: /system.slice/custom-registry.service

Dec 22 12:40:01 localhost etcdctl[10172]: index.domain.com:5000
Dec 22 12:40:01 localhost systemd[1]: Started Custom Registry Service.
Dec 22 12:40:01 localhost docker[10171]: Unable to find image '54.202.26.87:5000/registry' (tag: latest) locally
Dec 22 12:40:11 localhost docker[10171]: 2013/12/22 12:40:11 Invalid Registry endpoint: Get http://index2.domain.com:5000/v1/_ping: dial tcp 54.204.26.2...o timeout
Dec 22 12:40:11 localhost systemd[1]: custom-registry.service: main process exited, code=exited, status=1/FAILURE
Dec 22 12:40:11 localhost etcdctl[10191]: index.domain.com:5000
Dec 22 12:40:11 localhost systemd[1]: Unit custom-registry.service entered failed state.
Hint: Some lines were ellipsized, use -l to show in full.
```

You can see that `Process: 10171 ExecStart=/usr/bin/docker` exited with `status=1/FAILURE` and the log states that the index that we attempted to launch the container from, `54.202.26.87` wasn't valid, so the container image couldn't be downloaded.

## List status of all units

Listing all of the processes running on the box is too much information, but you can pipe the output into grep to find the services you're looking for. Here's all service files and their status:

```sh
sudo systemctl list-units | grep .service
```

## Start or stop a service

```sh
sudo systemctl start apache.service
```

```sh
sudo systemctl stop apache.service
```

## Kill a service

This will stop the process immediately:

```sh
sudo systemctl kill apache.service
```

## Restart a service

Restarting a service is as easy as:

```sh
sudo systemctl restart apache.service
```

If you're restarting a service after you changed its service file, you will need to reload all of the service files before your changes take effect:

```sh
sudo systemctl daemon-reload
```

## More information

<a class="btn btn-default" href="getting-started-with-systemd.md">Getting Started with systemd</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.service.html">systemd.service Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.unit.html">systemd.unit Docs</a>
