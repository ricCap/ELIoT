#! /bin/bash

set pipefail -euo

# Create directories to store Prometheus data and configuration
mkdir -p data/prometheus
mkdir -p config

# Give necessary permissions to to .sh files in the directory
chmod -R 765 ./*.sh
