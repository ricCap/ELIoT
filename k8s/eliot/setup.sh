#!/bin/bash

set -euo pipefail

kubectl create namespace eliot
kubectl apply -f bootstrap-server-deployment.yml
kubectl apply -f bootstrap-server-service.yml
kubectl apply -f server-deployment.yml
kubectl apply -f server-service.yml
kubectl apply -f devices-deployment.yml
