#!/bin/bash

source test_base.sh
export DEVICES_TEST_YAML="$ELIOT_K8S_HOME/eliot/medium.yaml"
export ELIOT_DEVICES=500
run
