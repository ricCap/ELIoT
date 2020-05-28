#!/bin/bash bash

set pipefail -euo

chmod -R 765 ./*.sh

# Create KIND cluster
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        authorization-mode: "AlwaysAllow"
  extraPortMappings:
  - containerPort: 30000 #Prometheus
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001 #Grafana
    hostPort: 30001
    protocol: TCP
  - containerPort: 30002 #Leshan Server
    hostPort: 30002
    protocol: TCP
  - containerPort: 30003 #Leshan Bootstrap Server
    hostPort: 30003
    protocol: TCP
EOF

services=("prometheus" "kube-state-metrics" "grafana" "eliot")
let service
for service in ${services[@]}; do
  echo
  echo "-------------Deploying $service----------"
  cd $service; ./setup.sh; cd ..
  echo "Done"
  echo "############################################"
done
