#!/usr/bin/env bash

set pipefail -euo

kubectl create namespace monitoring
kubectl apply -f cluster-role.yml
kubectl apply -f config-map.yml
kubectl apply -f deployment.yml
kubectl apply -f service.yml
