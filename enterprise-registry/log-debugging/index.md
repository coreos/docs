---
layout: docs
title: Enterprise Registry Log debugging
category: registry
weight: 5
---

# Enterprise Registry Log Debugging

## Personal debugging

When attempting to debug an issue, one should first consult the logs of the web workers running the Enterprise Registry.
This can be obtained in two different ways: manually or via a script.

Please note that both of these methods assume that they are being executed on the host machine.

### Manual

{% raw %}
```sh
CONTAINER_ID=$(docker ps | grep "coreos/registry" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tail -f ${LOG_LOCATION}/gunicorn_*/current
```
{% endraw %}

### Script

```sh
curl -L -f https://github.com/coreos/docs/blob/master/enterprise-registry/log-debugging/tail-gunicorn-logs.sh | sh
```

## Contacting support

When contacting support, one should always include a copy of the Enterprise Registry's log directory.
This can be obtained in two different ways: manually or via a script.

Please note that both of these methods assume that they are being executed on the host machine.

### Manual

{% raw %}
```sh
CONTAINER_ID=$(docker ps | grep "coreos/registry" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tar -zcvf registry-logs-$(date +%s).tar.gz ${LOG_LOCATION}
```
{% endraw %}

### Script

```sh
curl -L -f https://github.com/coreos/docs/blob/master/enterprise-registry/log-debugging/gzip-registry-logs.sh | sh
```
