#!/usr/bin/env bash

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
  - containerPort: 30001 #Grafana
    hostPort: 30001
    protocol: TCP
  - containerPort: 30000 #Prometheus
    hostPort: 30000
    protocol: TCP
EOF

echo
echo "-------------Deploying prometheus----------"
cd prometheus
./setup.sh
cd ..
echo "Done"
echo "############################################"

echo
echo "--------Deploying kube state metrics--------"
cd kube-state-metrics
./setup.sh
cd ..
echo "Done"
echo "############################################"

echo
echo "------------Deploying grafana---------------"
cd grafana
./setup.sh
cd ..
echo "Done"
echo "############################################"
