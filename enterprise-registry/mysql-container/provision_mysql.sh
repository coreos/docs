#!/bin/bash
# A simple shell script to provision a dedicated MySQL container for the CoreOS Enterprise Registery

# Edit the following three values to your liking:
MYSQL_USER="coreosuser"
MYSQL_DATABASE="enterpriseregistrydb"
MYSQL_CONTAINER_NAME="mysql"

# Do not edit these values:
# (creates a 32 char password for the MySQL root user and the Enterprise Registery DB user)
MYSQL_ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | sed 1q)
MYSQL_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | sed 1q)

echo "Pull the Oracle MySQL verified Docker image from the public Docker registry::
docker \
  pull \
  mysql:5.6;

echo "Start the Oracle MySQL container:"
# It will provision a blank database for the Enterprise Registery upon first start.
# This initial provisioning can take up to 30 seconds.
docker \
  run \
  --detach \
  --env MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
  --env MYSQL_USER=${MYSQL_USER} \
  --env MYSQL_PASSWORD=${MYSQL_PASSWORD} \
  --env MYSQL_DATABASE=${MYSQL_DATABASE} \
  --name ${MYSQL_CONTAINER_NAME} \
  --publish 3306:3306 \
  mysql:5.6;

# Sleep for 30 seconds to allow time for the DB to be provisioned:
sleep 30

# Echo the DB_URL that needs to be entered into the config.yaml file
echo "DB_URI: 'mysql+pymysql://${MYSQL_USER}:${MYSQL_PASSWORD}@db/${MYSQL_DATABASE}'"


