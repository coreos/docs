# Kubernetes network troubleshooting on CoreOS

Kubernetes networking issues can be debugged with familiar tools, once the isolated nature of the container abstraction is taken into account. This document explains some of the best places to start troubleshooting when network issues arise.

## First stop: DNS debugging

A common issue with Kubernetes networking is trouble with kube-dns, the Kubernetes DNS system. The official Kubernetes documentation includes a [guide to checking whether a cluster’s Kubernetes DNS works][k8s-dns-check].

Another technique is to forward a local port to the `kube-dns` pod's port 53:

<!-- {% raw %} -->
```sh
kubectl get pods --namespace=kube-system -l k8s-app=kube-dns \
-o template --template="{{range.items}}{{.metadata.name}}{{end}}" \
| xargs -I{} kubectl port-forward --namespace=kube-system {} 5300:53
```
<!-- {% endraw %} -->

This one-liner finds the pod in the `kube-system` namespace whose `k8s-app` property is `kube-dns`, and uses `xargs` to format that pod's name for a `kubectl port-forward` command. The result is that local port 5300 is forwarded to the pod's port 53. This allows host DNS tools to look up Kubernetes hostnames at your machine's port 5300:

```sh
$ dig +vc -p 5300 @127.0.0.1  frontend.default.svc.cluster.local

; <<>> DiG 9.10.3-P4-RedHat-9.10.3-12.P4.fc23 <<>> +vc -p 5300 @127.0.0.1 frontend.default.svc.cluster.local
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 157
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;frontend.default.svc.cluster.local. IN A

;; ANSWER SECTION:
frontend.default.svc.cluster.local. 30 IN A 10.3.0.119

;; Query time: 188 msec
;; SERVER: 127.0.0.1#5300(127.0.0.1)
;; WHEN: Fri Apr 29 07:24:30 EDT 2016
;; MSG SIZE  rcvd: 68
```

The next example shows a failed `dig` lookup of a service hostname that was expected to exist, but does not. Note the lack of an `ANSWER SECTION`, indicating no such hostname was found:

```sh
$ dig +vc -p 5300 @127.0.0.1  test-service.default.svc.cluster.local

; <<>> DiG 9.10.3-P4-RedHat-9.10.3-12.P4.fc23 <<>> +vc -p 5300 @127.0.0.1 test-service.default.svc.cluster.local
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 60543
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 0

;; QUESTION SECTION:
;test-service.default.svc.cluster.local.    IN A

;; AUTHORITY SECTION:
cluster.local.      60  IN  SOA ns.dns.cluster.local. hostmaster.skydns.local. 1461927600 28800 7200 604800 60

;; Query time: 119 msec
;; SERVER: 127.0.0.1#5300(127.0.0.1)
;; WHEN: Fri Apr 29 07:35:33 EDT 2016
;; MSG SIZE  rcvd: 117
```

## Debugging Docker bridge and other host networking issues on CoreOS

If you suspect the issue is actually with the host's networking, it may seem frustrating that CoreOS does not include some of the standard network utilities like `tcpdump` or `nmap`. However, CoreOS provides the [*toolbox*][toolbox], a special container that can install and run a complete userland, without needing everything installed on the base system.

Run the command `toolbox` and CoreOS will launch a container from the "Fedora" image, downloading it first if necessary. This container is executed with all kernel capabilities, mounts local filesystems for inspection, and attaches directly to the host network. After running the `toolbox` command, you will be at a shell inside this privileged container.

Once inside the toolbox container, install the desired tools:

```sh
# dnf install -y [package] [package] [package]...
```

Run debugging tools in the toolbox:

```sh
# tcpdump -i docker0
```

Exit the toolbox container by hitting `Ctrl`+`]` three times to stop it, leaving the base system unchanged. The downloaded container image will remain in the local image store on disk, but can be manually removed.

A first invocation of the `toolbox` command looks something like this:

```sh
core@test-inst ~ $ toolbox
latest: Pulling from library/fedora
6888fc827a3f: Pull complete
9bdb5101e5fc: Pull complete
Digest: sha256:1fa98be10c550ffabde65246ed2df16be28dc896d6e370dab56b98460bd27823
Status: Downloaded newer image for fedora:latest
core-fedora-latest
Spawning container core-fedora-latest on /var/lib/toolbox/core-fedora-latest.
Press ^] three times within 1s to kill container.
[root@test-inst ~]# dnf install -y iproute tcpdump nmap
[...DNF output omitted...]

Installed:
  iproute.x86_64 4.1.1-3.fc23                libpcap.x86_64 14:1.7.4-1.fc23
  linux-atm-libs.x86_64 2.5.1-13.fc23        nmap.x86_64 2:7.12-1.fc23
  nmap-ncat.x86_64 2:7.12-1.fc23             python.x86_64 2.7.11-3.fc23
  python-libs.x86_64 2.7.11-3.fc23           python-pip.noarch 7.1.0-1.fc23
  python-setuptools.noarch 18.0.1-2.fc23     tcpdump.x86_64 14:4.7.4-3.fc23

Complete!
[root@test-inst ~]# tcpdump -i docker0
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on docker0, link-type EN10MB (Ethernet), capture size 262144 bytes
[...]
```

## Debugging Kubernetes pod issues

Many pod network issues come down to container networking. Access to the container's network namespace is needed to troubleshoot these issues. Gaining access to a container namespace boils down to finding the container ID, and sometimes mapping it to the process ID running inside the container.

### Finding the ID of the right container

You can get the ID of the container(s) in a pod with `kubectl describe`:

```
$ kubectl describe pod redis-slave-1691881626-d3aft
[...]
Container ID:       docker://7236796e4f380a081d4c7538bfde2c132dd875fc294cd80df8d31e1cc76f8726
[...]
```

Here we’re interested in the part after “docker://” -- and in fact only the first 12 characters of that alphanumeric ID are usually needed.

If the pod has more than one container, additional examination of the pod manifest and/or `kubectl get logs` output should reveal the container ID to target.

Once you have the right container ID, you can target that container for debugging.

### Executing a shell in the target container

If the container includes your desired utility (such as busybox or another shell), execute it directly in the target container:

In Docker: `docker exec -ti [target container ID] [path to utility inside container, e.g. /bin/sh]`

In rkt: `rkt enter [target container ID] [path to utility inside container]`

### Attaching a debug container to the target container

Sometimes a container does not include a shell. A utility container with a shell and other debugging tools can be attached to the target container's network namespace.

#### For Docker containers:

Docker can attach one container to another container's network namespace. For example, a busybox container can be attached to the namespace, providing a shell to drive basic debugging tools:

```
docker run -ti --net container:[target container ID] [debug container image] [path to utility inside container]
```

This example connecting to port 6379, which is active in the target redis container, but failing to connect on port 8080, where no container process is listening:

```
core@k8s-onenode-1461695566 ~ $ docker run -ti --net container:7236796e4f38 \
--name busybox-diag busybox /bin/sh
/ # nc localhost 6379
/ # nc localhost 8080
nc: can't connect to remote host (127.0.0.1): Connection refused
/ #
```

#### For rkt containers:

Attach to rkt containers by using the namespace entry command, `nsenter`, to invoke rkt and another container with the `--net=host` option. This new container thinks it is attaching to the host network, but the "host" network it sees is actually the network namespace of the target container. To find a target process ID in a rkt container:

```sh
$ rkt status [container ID]
```

Once you have the target process ID, spawn the rkt debugging container, passing the target PID to `nsenter`:

```sh
nsenter -n -t [target PID] rkt run --net=host --interactive [debugging container image] --exec [program]
```

Here's a complete example showing a connection to port 12345 on the target container:

```
core@k8s-onenode-1461695566 ~ $ rkt list
UUID            APP             IMAGE NAME                                      STATE   CREATED         STARTED         NETWORKS
32f37e3e        busybox         registry-1.docker.io/library/busybox:latest     running 1 minute ago    1 minute ago    default:ip4=172.16.28.2
ff12150d        hyperkube       quay.io/coreos/hyperkube:v1.2.0_coreos.1        running 2 days ago      2 days ago
core@k8s-onenode-1461695566 ~ $ rkt status 32f37e3e
state=running
created=2016-04-29 10:15:56 +0000 UTC
started=2016-04-29 10:15:56 +0000 UTC
networks=default:ip4=172.16.28.2
pid=4272
exited=false
core@k8s-onenode-1461695566 ~ $ sudo nsenter -n -t 4272 \
rkt run --net=host --interactive --insecure-options=image \
docker://busybox --exec /bin/sh
image: using image from local store for image name coreos.com/rkt/stage1-coreos:1.2.1
image: using image from local store for url docker://busybox
/ # nc localhost:12345
foo
bar
```

This process can also be adapted to attach rkt containers to a Docker container's network namespace. In that case, retrieve the PID of the entrypoint in the Docker container this way:

<!-- {% raw %} -->
```sh
docker inspect -f '{{.State.Pid}}' [container ID]
```
<!-- {% endraw %} -->

[k8s-dns-check]: https://github.com/kubernetes/kubernetes/blob/release-1.2/cluster/addons/dns/README.md#how-do-i-test-if-it-is-working
[toolbox]: /os/docs/latest/install-debugging-tools.md
