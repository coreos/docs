CONTAINER_ID=$(docker ps | grep "coreos/quay" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tail -f ${LOG_LOCATION}/gunicorn_*/current
