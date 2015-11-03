CONTAINER_ID=$(docker ps | grep "coreos/registry" | awk '{print $1}')
LOG_LOCATION=$(docker inspect -f '{{ index .Volumes "/var/log" }}' ${CONTAINER_ID})
tar -zcvf registry-logs-$(date +%s).tar.gz ${LOG_LOCATION}
