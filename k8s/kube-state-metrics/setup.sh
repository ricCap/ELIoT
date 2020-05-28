#!/usr/bin/env bash

set pipefail -euo

kubectl apply -f cluster-role.yml
kubectl apply -f cluster-role-binding.yml
kubectl apply -f deployment.yml
kubectl apply -f service-account.yml
kubectl apply -f service.yml
