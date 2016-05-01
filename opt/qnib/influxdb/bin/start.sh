#!/usr/local/bin/dumb-init /bin/bash

PIDFILE=/var/run/influxdb.pid

if [ "X${INFLUXDB_CLUSTER_PEERS}" != "X" ];then
 	INFLUXD_JOIN="-join ${INFLUXDB_CLUSTER_PEERS}"
fi

CONSUL_RELOAD=0
if [ ${INFLUXDB_OPENTSDB_ENABLED} != "true" ];then
    rm -f /etc/consul.d/influxdb_opentsdb.json
    CONSUL_RELOAD=1
fi
if [ ${INFLUXDB_GRAPHITE_ENABLED} != "true" ];then
    rm -f /etc/consul.d/influxdb_graphite.json
    CONSUL_RELOAD=1
fi
if [ ${CONSUL_RELOAD} -eq 1 ];then
    consul reload
fi

## Check if eth0 already exists
ADDR=eth0
ip addr show ${ADDR} > /dev/null
EC=$?
if [ ${EC} -eq 1 ];then
    echo "## Wait for pipework to attach device 'eth0'"
    pipework --wait
fi

## Consul-Template
consul-template -consul=localhost:8500 -once -template="etc/consul-templates/influxdb/influxdb.conf.ctmpl:/etc/influxdb/influxdb.conf"
## Start
influxd -pidfile ${PIDFILE} -config /etc/influxdb/influxdb.conf ${INFLUXD_OPTS} 
