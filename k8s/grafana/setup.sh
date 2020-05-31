#!/bin/bash

set -euo pipefail

kubectl apply -f config-map.yml
kubectl apply -f deployment.yml
kubectl apply -f service.yml
