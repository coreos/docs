---
layout: docs
title: Enterprise Registry Log debugging
category: registry
weight: 5
---

# Enterprise Registry Log Debugging

To aid in debugging issues such as LDAP configuration you can tail the logs of the Enterprise Registry container from the Docker host as shown below:

```sh
CONTAINER_ID=$(docker ps | grep "coreos/registry:latest" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tail -f  ${LOG_LOCATION}/gunicorn_web/* ${LOG_LOCATION}/gunicorn_registry/* ${LOG_LOCATION}/gunicorn_verbs/*
```

Alternatively you can download a simple shell script to perform the steps above:

```sh
curl --location https://github.com/coreos/docs/blob/master/enterprise-registry/log-debugging/tail_gunicorn_logs.sh -o /tmp/tail_gunicorn_logs.sh -#
```

Then run:

```sh
chmod -c +x /tmp/tail_gunicorn_logs.sh
/tmp/tail_gunicorn_logs.sh
```
