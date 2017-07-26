## Redirecting syslog to /dev/stdout

By default, Quay Enterprise saves logs most relevant for debugging to `/var/log/syslog` within the container. [syslog-ng][syslog-ng] can be configured to redirect these logs to `/dev/stdout` which will allow for collection by most logging solutions:

Create `syslog-ng-extra.conf` with the following content:

```
source s_docker_syslog { file("/var/log/syslog"); };
destination d_docker_syslog { file("/dev/stdout"); };
log {
    source(s_docker_syslog);
    destination(d_docker_syslog);

};
```
### Single Container

Place the `syslog-ng-extra.conf` file into the configuration directory:

```
$ ls quay/config/
config.yaml   license       ssl.cert      ssl.key     syslog-ng-extra.conf
```

Restart the Quay Enterprise container:

```
$ docker ps
0f6c27088c32        quay.io/coreos/quay:v2.4.0 "/sbin/my_init"          27 hours ago        Up 3 hours          0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 8443/tcp   epic_banach

docker restart 0f6c27088c32
```

### Kubernetes

base64 encode the `syslog-ng-extra.conf` file:

```
$ cat /config/syslog-ng-extra.conf | base64 -w 0

c291cmNlIHNfZG9ja2VyX3N5c2xvZyB7IGZpbGUoIi92YXIvbG9nL3N5c2xvZyIpOyB9Owpk
ZXN0aW5hdGlvbiBkX2RvY2tlcl9zeXNsb2cgeyBmaWxlKCIvZGV2L3N0ZG91dCIpOyB9Owpsb
2cgeyAKCXNvdXJjZShzX2RvY2tlcl9zeXNsb2cpOyAKCWRlc3RpbmF0aW9uKGRfZG9ja2VyX
3N5c2xvZyk7IAoKfTsK
```

Edit the Quay Enterprise config secret file:

```
$ kubectl --namespace quay-enterprise edit secret/quay-enterprise-config-secret
```

Add an entry for the `syslog-ng-extra.conf` file:

```
syslog-ng-extra.conf:
<-base64 encoded syslog-ng-extra.conf->
```

Delete `quay-enterprise-app` pods to trigger the quay-enterprise deployment to schedule pods with the updated configuration:

```
$ kubectl -n quay-enterprise get pods
NAME                                     READY     STATUS    RESTARTS   AGE
quay-enterprise-app-1576414776-vv4vv     1/1       Running   0          3h
quay-enterprise-app-1623234786-twrc2     1/1       Running   0          3h
quay-enterprise-redis-3163299701-mdw95   1/1       Running   0          3h
```

```
$ kubectl -n quay-enterprise delete pod/quay-enterprise-app-1576414776-vv4vv
$ kubectl -n quay-enterprise delete pod/quay-enterprise-app-1623234786-twrc2
```

[syslog-ng]: https://en.wikipedia.org/wiki/Syslog-ng

