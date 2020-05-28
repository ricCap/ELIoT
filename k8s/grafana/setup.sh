#!/usr/bin/env bash

set pipefail -euo

kubectl apply -f config-map.yml
kubectl apply -f deployment.yml
kubectl apply -f service.yml
