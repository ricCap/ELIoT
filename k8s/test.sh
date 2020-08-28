#!/bin/bash

set pipefail -euo

readonly ELIOT_K8S_HOME="$(pwd)"
readonly LOG_FILE="$ELIOT_K8S_HOME/test.log"
readonly KIND_CONFIG_PATH="$ELIOT_K8S_HOME/test_kind_config.yaml"
readonly TEST_TIMES_FILE="$ELIOT_K8S_HOME/test_times.log"

readonly RESOURCE_QUOTA_MEMORY_MB=4096
readonly ELIOT_DEVICE_AVG_SIZE_MB=50
readonly SCALEUP_MAX_CONTAINERS=$RESOURCE_QUOTA_MEMORY_MB/$ELIOT_DEVICE_AVG_SIZE_MB
readonly STABILIZATION_PERIOD_SECONDS=180
readonly DEFAULT_ELIOT_PODS=2

export TEST_COUNTER=0
export DEFAULT_IDLE_PODS=0

function log(){
  local message=$1
  local additional_log_file=$2
  echo "$(date +"%F,%T,%Z") $message" >> $LOG_FILE 2>&1
  if [[ -n ${additional_log_file:-} ]]; then
    echo "$(date +"%F,%T,%Z") $message" >> $additional_log_file 2>&1
  fi
  echo "$(date +"%F,%T,%Z") $message"
}

function wait_system_idle(){
  sleep 10
  local running_pods target_idle_pods
  target_idle_pods=$1
  running_pods=$(kubectl get pods -A --field-selector=status.phase=Running -o json | jq '.items | length')

  while [[ $running_pods -ne $target_idle_pods ]]; do
    log "Waiting pods; target: $target_idle_pods running: $running_pods"
    sleep 10
    running_pods=$(kubectl get pods -A --field-selector=status.phase=Running -o json | jq '.items | length')
  done

  log "System idle: target: $target_idle_pods, running: $running_pods"
}

function do_scale(){
  local scale_time_delta_seconds=$1
  local step_up=$2
  local step_down=$3
  local target_containers=$step_up

  log "Resetting deployed containers to 0"
  $ELIOT_K8S_HOME/setup.sh --scale eliot-weather 0
  wait_system_idle $DEFAULT_IDLE_PODS

  log "Starting scaling"
  while [[ $target_containers -le $SCALEUP_MAX_CONTAINERS && $target_containers -le 1000 ]]; do
    log "Scaling up: target=$target_containers"
    $ELIOT_K8S_HOME/setup.sh --scale eliot-weather $target_containers

    if [[ -n "${step_down:-}" ]]; then
      local target_containers_down=$(($target_containers - $step_down))
      log "Scaling down: target=$target_containers_down"
      $ELIOT_K8S_HOME/setup.sh --scale eliot-weather $target_containers_down
    fi

    sleep $scale_time_delta_seconds
    target_containers=$((target_containers + $step_up))
  done

    wait_system_idle $((target_containers - $step_up - ${step_down:-0} + $DEFAULT_IDLE_PODS))
}

function scale_test(){
  local scale_time_delta_seconds=$1
  local step_up=$2
  local step_down=$3
  TEST_COUNTER=$((TEST_COUNTER + 1))
  log "Starting test $TEST_COUNTER: delta: $scale_time_delta_seconds seconds, step_up $step_up, step_down: ${step_down:-}" $TEST_TIMES_FILE
  do_scale $scale_time_delta_seconds $step_up $step_down
  log "Test $TEST_COUNTER completed, waiting for the stabilization period"
  sleep $STABILIZATION_PERIOD_SECONDS
  log "Test $TEST_COUNTER stabilization period elapsed, test completed" $TEST_TIMES_FILE
}

function configure(){
  log "Deleting already-existing clusters"
  kind delete cluster

  log "Deploying all default services excluding ELIoT"
  $ELIOT_K8S_HOME/setup.sh -k --kind-config-path $KIND_CONFIG_PATH -s "prometheus grafana kube-state-metrics node-exporter"

  log "Default services deployed, waiting for the containers to start up"
  DEFAULT_IDLE_PODS=$(kubectl get pods -A -o json | jq '.items | length')
  wait_system_idle $DEFAULT_IDLE_PODS
  log "All default services have been deployed successfully"

  log "Starting the test"
  log "Deploying default ELIoT configuration"
  $ELIOT_K8S_HOME/setup.sh -s "eliot"
  $ELIOT_K8S_HOME/setup.sh --scale all 0

  log "Waiting for the system to stabilize"
  DEFAULT_IDLE_PODS=$((DEFAULT_IDLE_PODS + $DEFAULT_ELIOT_PODS))
  wait_system_idle $DEFAULT_IDLE_PODS
  log "All pods have been deployed successfully, waiting for the stabilization period"
  sleep $STABILIZATION_PERIOD_SECONDS
}

function test(){
    local step=50
    local scale_time_delta_seconds=10
    scale_test $scale_time_delta_seconds $step

    step=50
    scale_time_delta_seconds=20
    scale_test $scale_time_delta_seconds $step

    step=100
    scale_time_delta_seconds=10
    scale_test $scale_time_delta_seconds $step

    step=100
    scale_time_delta_seconds=20
    scale_test $scale_time_delta_seconds $step

    local step_up=50
    local step_down=25
    scale_time_delta_seconds=10
    scale_test $scale_time_delta_seconds $step_up $step_down

    step_up=50
    step_down=25
    scale_time_delta_seconds=20
    scale_test $scale_time_delta_seconds $step_up $step_down
}

function main(){
  cd $ELIOT_K8S_HOME
  log "Configuring test"
  configure
  log "Starting tests"
  test
  log "Tests completed"
  log "You should delete the cluster manually using kind delete cluster"
}

main
