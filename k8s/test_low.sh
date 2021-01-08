#!/bin/bash

export DEVICES_TEST_YAML="$ELIOT_K8S_HOME/eliot/low.yaml"
export ELIOT_DEVICES=200
source test_base.sh
run
