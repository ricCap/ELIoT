#!/bin/bash

set pipefail -euo

readonly ELIOT_K8S_HOME="$(pwd)"
readonly LOG_FILE="$ELIOT_K8S_HOME/test.log"
readonly KIND_CONFIG_PATH="$ELIOT_K8S_HOME/test_kind_config.yaml"

readonly RESOURCE_QUOTA_MEMORY_MB=4096
readonly ELIOT_DEVICE_AVG_SIZE_MB=40
readonly SCALEUP_MAX_CONTAINERS=$RESOURCE_QUOTA_MEMORY_MB/$ELIOT_DEVICE_AVG_SIZE_MB
readonly STABILIZATION_PERIOD_SECONDS=120

export TEST_COUNTER=0

function log(){
  local message=$1
  echo "$(date +"%F,%T,%Z") $message" >> $LOG_FILE 2>&1
  echo "$(date +"%F,%T,%Z") $message"
}

function wait_system_idle(){
  local running_pods=$(kubectl get pods -A --field-selector=status.phase=Running -o json | jq '.items | length')
  local deployed_pods=$(kubectl get pods -A -o json | jq '.items | length')

  while [[ $deployed_pods > $running_pods ]]; do
    log "Waiting pods; deployed: $deployed_pods, running: $running_pods"
    sleep 10
    running_pods=$(kubectl get pods -A --field-selector=status.phase=Running -o json | jq '.items | length')
    deployed_pods=$(kubectl get pods -A -o json | jq '.items | length')
  done
}

function do_scale(){
  local step=$1
  local scale_time_delta_seconds=$2

  local deployed_eliot_containers=$(kubectl get pods -n eliot -o json | jq '.items | length')

  while [[ $deployed_eliot_containers -le $SCALEUP_MAX_CONTAINERS && $deployed_eliot_containers -le 1000 ]]; do
    local target_containers=$((deployed_eliot_containers + $step))
    log "Scaling up: target=$target_containers"
    $ELIOT_K8S_HOME/setup.sh --scale all $target_containers
    deployed_eliot_containers=$(kubectl get pods -n eliot -o json | jq '.items | length')
    sleep $scale_time_delta_seconds
  done
}

function scale_up_test(){
  local step=$1
  local scale_time_delta_seconds=$2
  TEST_COUNTER=$((TEST_COUNTER + 1))
  log "Starting test $TEST_COUNTER: step $step, delta: $delta seconds"
  do_scale $step $scale_time_delta_seconds
  wait_system_idle
  log "Test $TEST_COUNTER completed, waiting for the stabilization period"
  sleep $STABILIZATION_PERIOD_SECONDS
}

function scale_down_test(){
  local step_up=$1
  local step_down=$2
  local scale_time_delta_seconds=$3
  TEST_COUNTER=$((TEST_COUNTER + 1))
  log "Starting test $TEST_COUNTER: step $step, delta: $scale_time_delta_seconds seconds"
  do_scale $step_up $scale_time_delta_seconds &
  do_scale $step_down $scale_time_delta_seconds &
  wait_system_idle
  log "Test $TEST_COUNTER completed, waiting for the stabilization period"
  sleep $STABILIZATION_PERIOD_SECONDS
}

function configure(){
  log "Deleting already-existing clusters"
  kind delete cluster

  log "Deploying all default services excluding ELIoT"
  $ELIOT_K8S_HOME/setup.sh -k --kind-config-path $KIND_CONFIG_PATH -s "prometheus grafana kube-state-metrics node-exporter"

  log "Default services deployed, waiting for the containers to start up"
  wait_system_idle
  log "All default services have been deployed successfully"

  log "Starting the test"
  log "Deploying default ELIoT configuration"
  $ELIOT_K8S_HOME/setup.sh -s "eliot"
  $ELIOT_K8S_HOME/setup.sh --scale all 0

  log "Enforcing resource quota on eliot namespace"
  #MEMORY="${MEMORY=$RESOURCE_QUOTA_MEMORY_MB}Mi" envsubst < "$ELIOT_K8S_HOME/eliot/resource-quota.yml" | kubectl apply -f -
  # MEMORY="1Gi" CPU="1" envsubst < resource-quota.yml | kubectl apply -f -

  log "Waiting for the system to stabilize"
  wait_system_idle
  sleep $STABILIZATION_PERIOD_SECONDS
}

function test(){
    local step=50
    local scale_time_delta_seconds=20
    scale_up_test $step $scale_time_delta_seconds

    step=100
    scale_time_delta_seconds=10
    scale_up_test $step $scale_time_delta_seconds

    step=100
    scale_time_delta_seconds=20
    scale_up_test $step $scale_time_delta_seconds

    step=100
    scale_time_delta_seconds=20
    scale_up_test $step $scale_time_delta_seconds

    local step_up=100
    local step_down=-50
    scale_time_delta_seconds=10
    scale_down_test $step_up $step_down $scale_time_delta_seconds

    step_up=100
    step_down=-50
    scale_time_delta_seconds=20
    scale_down_test $step_up $step_down $scale_time_delta_seconds
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
