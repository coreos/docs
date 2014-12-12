#!/bin/bash
# A simple shell script to tail the gunicorn logs of the CoreOS Enterprise Registery container

CONTAINER_ID=$(docker ps | grep "coreos/registry:latest" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tail -f  ${LOG_LOCATION}/gunicorn_web/* ${LOG_LOCATION}/gunicorn_registry/* ${LOG_LOCATION}/gunicorn_verbs/*
