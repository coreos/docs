---
layout: docs
title: LDAP debugging
category: registry
forkurl: https://github.com/coreos/docs/blob/master/enterprise-registry/ldap-logging/index.md
weight: 5
---

# LDAP debugging
To aid in LDAP debugging you can tail the logs of the Enterprise Registry container from the Docker host as shown below:

```shell
CONTAINER_ID=$(docker ps | grep "coreos/registry:latest" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tail -f  ${LOG_LOCATION}/gunicorn_web/* ${LOG_LOCATION}/gunicorn_registry/* ${LOG_LOCATION}/gunicorn_verbs/*
```

Alternatively you can download a simple shell script to perform the steps above:
```shell
curl --location {{site.url}}/docs/enterprise-registry/ldap-logging/tail_gunicorn_logs.sh -o /tmp/tail_gunicorn_logs.sh -#
```
Then run:
```shell
chmod -c +x /tmp/tail_gunicorn_logs.sh
/tmp/tail_gunicorn_logs.sh
```
