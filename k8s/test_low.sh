#!/bin/bash

set pipefail -euo

readonly ELIOT_K8S_HOME="$(pwd)"
readonly LOG_FILE="$ELIOT_K8S_HOME/test.log"
readonly KIND_CONFIG_PATH="$ELIOT_K8S_HOME/test_kind_config.yaml"

readonly STABILIZATION_PERIOD_SECONDS=30
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

  kubectl create namespace eliot
  kubectl apply -f "$ELIOT_K8S_HOME/eliot/bootstrap-server-deployment.yml"
  kubectl apply -f "$ELIOT_K8S_HOME/eliot/bootstrap-server-service.yml"
  kubectl apply -f "$ELIOT_K8S_HOME/eliot/server-deployment.yml"
  kubectl apply -f "$ELIOT_K8S_HOME/eliot/server-service.yml"

  log "Waiting for the system to stabilize"
  DEFAULT_IDLE_PODS=$(kubectl get pods -A -o json | jq '.items | length')
  wait_system_idle $DEFAULT_IDLE_PODS
  log "All pods have been deployed successfully, waiting for the stabilization period"
  kubectl apply -f "$ELIOT_K8S_HOME/eliot/low.yaml"
  DEFAULT_IDLE_PODS=$((DEFAULT_IDLE_PODS + 200))
  wait_system_idle $DEFAULT_IDLE_PODS

  sleep $STABILIZATION_PERIOD_SECONDS
  log "Starting observe"
  python "$ELIOT_K8S_HOME/server_api_call.py"
}

function main(){
  cd $ELIOT_K8S_HOME
  log "Configuring test"
  configure
  log "Tests completed"
  log "You should delete the cluster manually using kind delete cluster"
}

main
