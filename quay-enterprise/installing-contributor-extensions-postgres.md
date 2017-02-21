# Installing Contributor Extensions for Postgres

As of release 2.1.0 Quay Enterprise requires the [pg_trgm](https://www.postgresql.org/docs/current/static/pgtrgm.html) extension when using Postgres. This extension ships as part of the [Additional Supplied Modules](https://www.postgresql.org/docs/current/static/contrib.html). The requirements to allow extensions to be installed can be satisfied via package management tools on Debian and RedHat-based systems.

## Debian/Ubuntu

```
# apt-get update
# apt-get install postgresql-contrib -y
```

## Redhat/CentOS

```
# yum install postgresql-contrib
```
## Fedora

```
# dnf install postgresql-contrib
```

## Docker 
The [library/postgres](https://hub.docker.com/_/postgres/) container includes `postgresql-contrib` package by default.

If using a container based on an OS above simply modify the Dockerfile to install `postgresql-contrib` package. If using an OS base that is not listed in may be required install `contrib` from [source](https://www.postgresql.org/docs/current/static/contrib.html). 
