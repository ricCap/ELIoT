#!/bin/bash
#set -euo pipefail
chmod -R 765 ./*.sh

services=("prometheus" "kube-state-metrics" "grafana" "eliot")

if [[ $# -eq 0 ]]; then
  echo "Try setup.sh -h"
  exit
fi

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -k|--kind)
    command="kind"
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
  -h|--help|*)
    echo "Services are automatically deployed when creating a cluster"
    echo
    echo "-k|--kind kind               Create a kind cluster"
    echo "-a|--admin                   Deploy a k8s cluster using kubeadm"
    echo '-s|--services A || "A B C"   Deploy a single service A or a list of services "A B C"'
    echo "-d|--default-services        Deploy default services"
    echo "-s|--show-default-services   Show services that are deployed by default"
    echo "--no-services                Do not deploy default services"
    exit
    ;;
esac; shift; done

if [[ -n "$command" ]]; then
  if [[ "$command" == 'kind' ]]; then
    kind create cluster --config=../config/kind.yml
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
