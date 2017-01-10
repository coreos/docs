# Setting up a MySQL Docker container

If you don't have an existing MySQL system to host the Quay Enterprise database on then you can run the steps below to create a dedicated MySQL container using the Oracle MySQL verified Docker image from [https://registry.hub.docker.com/_/mysql/](https://registry.hub.docker.com/_/mysql/).

```sh
docker pull mysql:5.7
```

Edit these values to your liking:

```sh
MYSQL_USER="coreosuser"
MYSQL_DATABASE="enterpriseregistrydb"
MYSQL_CONTAINER_NAME="mysql"
```
Do not edit these values:
(creates a 32 char password for the MySQL root user and the Quay Enterprise DB user)

```sh
MYSQL_ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | sed 1q)
MYSQL_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | sed 1q)
```

Start the MySQL container and create a new DB for Quay Enterprise:

```sh
docker \
  run \
  --detach \
  --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
  --env MYSQL_USER=${MYSQL_USER} \
  --env MYSQL_PASSWORD=${MYSQL_PASSWORD} \
  --env MYSQL_DATABASE=${MYSQL_DATABASE} \
  --name ${MYSQL_CONTAINER_NAME} \
  --publish 3306:3306 \
  mysql:5.7;
```

Wait about 30 seconds for the new DB to be created before testing the connection to the DB, the MySQL container will not respond during the initial DB creation process.


Alternatively you can download a simple shell script to perform the steps above:

```sh
curl --location https://raw.githubusercontent.com/coreos/docs/master/quay-enterprise/provision_mysql.sh -o /tmp/provision_mysql.sh -#
```
Then run:

```sh
chmod -c +x /tmp/provision_mysql.sh
/tmp/provision_mysql.sh
```

Note: Using Percona v5.6 for the MySQL container is known to not work at this point in time.

<!-- BEGIN ANALYTICS --> [![Analytics](http://ga-beacon.prod.coreos.systems/UA-42684979-9/github.com/coreos/docs/quay-enterprise/mysql-container.md?pixel)]() <!-- END ANALYTICS -->