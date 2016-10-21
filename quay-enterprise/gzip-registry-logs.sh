CONTAINER_ID=$(docker ps | grep "coreos/quay" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tar -zcvf quay-logs-$(date +%s).tar.gz ${LOG_LOCATION}
