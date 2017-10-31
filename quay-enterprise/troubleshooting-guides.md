# Quay Enterprise Troubleshooting guides

Common failure modes and best practices for recovery.

* [I'm receiving HTTP Status Code 429][http-429]
* [I'm authorized but I'm still getting 403s][auth-403]
* [Base image pull in Dockerfile fails with 403][dockerfile-403]
* [Cannot add a build trigger][build-trigger]
* [Build logs are not loading][build-logs]
* [I'm receiving "Cannot locate specified Dockerfile"][no-dockerfile]
* [Could not reach any registry endpoint][registry-endpoint]
* [Cannot access private repositories using EC2 Container Service][ec2-service]
* [Docker is returning an i/o timeout][io-timeout]
* [Docker login is failing with an odd error][docker-login]
* [Pulls are failing with an odd error][pull-failure]
* [I just pushed but the timestamp is wrong][wrong-timestamp]
* [Pulling Private Quay.io images with Marathon/Mesos fails][mesos-fail]


[http-429]: http://docs.quay.io/issues/429.html
[auth-403]: http://docs.quay.io/issues/auth-failure.html
[dockerfile-403]: http://docs.quay.io/issues/base-pull-issue.html
[build-trigger]: http://docs.quay.io/issues/cannot-add-trigger.html
[build-logs]: http://docs.quay.io/issues/cannot-load-build-logs.html
[no-dockerfile]: http://docs.quay.io/issues/cannot-locate-dockerfile.html
[registry-endpoint]: http://docs.quay.io/issues/could-not-reach-any-registry-endpoint.html
[ec2-service]: http://docs.quay.io/issues/ecs-auth-failure.html
[io-timeout]: http://docs.quay.io/issues/iotimeout.html
[docker-login]: http://docs.quay.io/issues/odd-login-failure.html
[pull-failure]: http://docs.quay.io/issues/odd-pull-failure.html
[wrong-timestamp]: http://docs.quay.io/issues/push-timestamp-wrong.html
[mesos-fail]: http://docs.quay.io/issues/quay-mesos.html
