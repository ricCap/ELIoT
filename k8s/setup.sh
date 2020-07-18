#!/bin/bash
chmod -R 765 ./*.sh

export KIND_CONFIG_PATH="../config/kind.yml"

services=("prometheus" "kube-state-metrics" "grafana" "eliot" "node-exporter")

if [[ $# -eq 0 ]]; then
  echo "Try setup.sh -h"
  exit
fi

# Scale eliot devices
function scale() {
  readonly TARGET=$1
  readonly REPLICAS=$2

  if [[ "$TARGET" == "all" ]]; then
    kubectl scale deployment.v1.apps/eliot-presence -n eliot --replicas=$REPLICAS
    kubectl scale deployment.v1.apps/eliot-radiator -n eliot --replicas=$REPLICAS
    kubectl scale deployment.v1.apps/eliot-weather -n eliot --replicas=$REPLICAS
    kubectl scale deployment.v1.apps/eliot-light -n eliot --replicas=$REPLICAS
  else
    kubectl scale deployment.v1.apps/$1 -n eliot --replicas=$REPLICAS
  fi
}

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -k|--kind)
    command="kind"
    ;;
  --kind-config-path)
    shift; KIND_CONFIG_PATH=$1
    ;;
  -s|--services)
    shift; services=($1)
    ;;
  -a|--admin)
    command="kubeadm"
    ;;
  -d|--default-services)
    ;;
  --show-default-services)
    echo ${services[@]}
    exit
    ;;
  --no-services)
    services=()
    ;;
  --scale)
    shift; target=$1
    shift; replicas=$1
    scale $target $replicas
    exit
    ;;
  -h|--help)
    echo "Services are automatically deployed when creating a cluster"
    echo
    echo "-k|--kind                    Create a kind cluster"
    echo "-a|--admin                   Deploy a k8s cluster using kubeadm"
    echo '-s|--services A || "A B C"   Deploy a single service A or a list of services "A B C"'
    echo "-d|--default-services        Deploy default services"
    echo "--show-default-services      Show services that are deployed by default"
    echo "--scale TARGET REPLICAS      Scale the target device to number of replicas; target \"all\" is allowed"
    echo "--no-services                Do not deploy default services"
    exit
    ;;
  *)
    echo "Command not recognized $1: use -h or --help"
esac; shift; done

if [[ -n "$command" ]]; then
  if [[ "$command" == 'kind' ]]; then
    kind create cluster --config=$KIND_CONFIG_PATH
  elif [[ "$command" == 'kubeadm' ]]; then
    ./setup-adm.sh
  fi
fi

# Deploy services
let service
for service in ${services[@]}; do
  echo
  echo "-------------Deploying $service----------"
  cd $service; ./setup.sh; cd ..
  echo "Done"
  echo "############################################"
done
