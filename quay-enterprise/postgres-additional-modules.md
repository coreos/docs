# Installing Contributor Extensions for Postgres

As of release 2.1.0, Quay Enterprise requires the [pg_trgm][pg_trm] extension when using PostgreSQL. This extension is part of the [Additional Supplied Modules][Additional Supplied Modules]. These modules can be installed with standard package management tools on Debian and RedHat-based systems.

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
The [library/postgres][library/postgres] container includes the `postgresql-contrib` package.

If using a container based on one of the above operating systems, modify the container's Dockerfile to install the postgresql-contrib package. Containers built FROM other operating systems may need to [install the additional modules from source][source]. 

## PostgreSQL on Amazon RDS

The `postgresql-contrib package` is included.

[pg_trm]: https://www.postgresql.org/docs/current/static/pgtrgm.html
[Additional Supplied Modules]: https://www.postgresql.org/docs/current/static/contrib.html
[library/postgres]: https://hub.docker.com/_/postgres/
[source]: https://www.postgresql.org/docs/current/static/contrib.html
