---
layout: docs
title: Enterprise Registry Log Debugging
category: registry
sub_category: setup
weight: 5
---

# Enterprise Registry Log Debugging

## Personal debugging

When attempting to debug an issue, one should first consult the logs of the web workers running the Enterprise Registry.
Please note that both of these methods assume that they are being executed on the host machine.

{% raw %}
```sh
CONTAINER_ID=$(docker ps | grep "coreos/registry" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tail -f ${LOG_LOCATION}/gunicorn_*/current
```
{% endraw %}

The aforementioned shell commands are also available in script form at https://github.com/coreos/docs/blob/master/enterprise-registry/log-debugging/tail-gunicorn-logs.sh

## Contacting support

When contacting support, one should always include a copy of the Enterprise Registry's log directory.
Please note that both of these methods assume that they are being executed on the host machine.

{% raw %}
```sh
CONTAINER_ID=$(docker ps | grep "coreos/registry" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tar -zcvf registry-logs-$(date +%s).tar.gz ${LOG_LOCATION}
```
{% endraw %}

The aforementioned shell commands are also available in script form at https://github.com/coreos/docs/blob/master/enterprise-registry/log-debugging/gzip-registry-logs.sh
