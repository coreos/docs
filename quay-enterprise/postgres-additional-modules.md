# Installing Contributor Extensions for Postgres

As of release 2.1.0, Quay Enterprise requires the [pg_trgm][postgres-trgm] extension when using PostgreSQL. This extension is part of the [Additional Supplied Modules][postgres-additional-modules]. These modules can be installed with standard package management tools on Debian and RedHat-based systems.

## Debian/Ubuntu

```
# apt-get update
# apt-get install postgresql-contrib
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
The [library/postgres][postgres-contrib-docker] container includes the `postgresql-contrib` package.

If using a container based on one of the above operating systems, modify the container's Dockerfile to install the postgresql-contrib package. Containers built FROM other operating systems may need to [install the additional modules from source][source-install]. 

## PostgreSQL on Amazon RDS

The `postgresql-contrib package` is included.


[postgres-additional-modules]: https://www.postgresql.org/docs/current/static/contrib.html
[postgres-contrib-docker]: https://hub.docker.com/_/postgres/
[postgres-trgm]: https://www.postgresql.org/docs/current/static/pgtrgm.html
[source-install]: https://www.postgresql.org/docs/current/static/contrib.html
