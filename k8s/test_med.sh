#!/bin/bash

export DEVICES_TEST_YAML="$ELIOT_K8S_HOME/eliot/medium.yaml"
export ELIOT_DEVICES=500
source test_base.sh
run
