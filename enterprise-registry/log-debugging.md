# Enterprise Registry Log Debugging

## Personal debugging

When attempting to debug an issue, one should first consult the logs of the web workers running the Enterprise Registry.

## Visit the Management Panel

Sign in to a super user account and visit `http://yourregister/superuser` to view the management panel:

<img src="img/superuser.png" class="img-center" alt="Enterprise Registry Management Panel"/>

## View the logs for each service

- Click the logs tab (<span class="fa fa-bug"></span>)
- To view logs for each service, click the service name at the top. The logs will update automatically.

## Contacting support

When contacting support, one should always include a copy of the Enterprise Registry's log directory.

To download logs, click the "<i class="fa fa-download"></i> Download All Local Logs (.tar.gz)" link

## Shell script to download logs

The aforementioned operations are also available in script form at <a href="https://github.com/coreos/docs/blob/master/enterprise-registry/log-debugging/gzip-registry-logs.sh">https://github.com/coreos/docs/blob/master/enterprise-registry/log-debugging/gzip-registry-logs.sh</a>