#!/bin/bash

set pipefail -euo

export DEVICES_TEST_YAML="$(pwd)/eliot/medium.yaml"
source test_base.sh

export ELIOT_DEVICES=100

function test(){
  $ELIOT_K8S_HOME/setup.sh --scale eliot-latency-sensor-medium 0
  sleep 300
  $ELIOT_K8S_HOME/setup.sh --scale eliot-latency-sensor-medium 50
  observe
  sleep 300
  $ELIOT_K8S_HOME/setup.sh --scale eliot-latency-sensor-medium 100
  observe
  sleep 300
  $ELIOT_K8S_HOME/setup.sh --scale eliot-latency-sensor-medium 150
  observe
  sleep 300
  $ELIOT_K8S_HOME/setup.sh --scale eliot-latency-sensor-medium 200
  observe
  sleep 300
  $ELIOT_K8S_HOME/setup.sh --scale eliot-latency-sensor-medium 250
  observe
  sleep 300
}

cd $ELIOT_K8S_HOME
log "Configuring test"
configure
test
log "Tests completed"
log "You should delete the cluster manually using kind delete cluster"
