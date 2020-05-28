#! /bin/bash

set pipefail -euo

# Create directories to store Prometheus data and configuration
mkdir -p data/prometheus
mkdir -p config

# Allow prometheus to write in the directory on the host machine
chmod -R 755 data/prometheus
chmod -R 755 config
