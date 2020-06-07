#!/bin/bash

export NODE_EXPORTER_VERSION="1.9.1"

set -euo pipefail

helm install stable/prometheus-node-exporter --version $NODE_EXPORTER_VERSION --generate-name --set prometheus.monitor.namespace=monitoring --set namespaceOverride="monitoring"
